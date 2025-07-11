(import asyncio)
(import logging)
(import json)
(import sys)
(import os)
(import logging [getLogger :as get-logger])
(import inspect [isawaitable])

(import aiohttp [ClientSession])

(import tools.toolkit [gather-toolkit])
(import .aiostd [AioStd])

(require core.macros *)


(defclass Agent []
  (defm __init__ [prompt model log-level]
    (setv self.log (get-logger f"{__class__.__name__}-{model}"))
    (logging.basicConfig :level (logging.getLevelName log-level))
    (.debug self.log "loading toolkit...")
    (setv #(self.tools-schema self.tools) (gather-toolkit))
    (setv self.messages [{"role" "user" "content" prompt}])
    (setv self.model model)
    (setv self.endpoint "https://api.openai.com/v1/responses")
    (if (setx api-key (.getenv os "OPENAI_API_KEY"))
      (setv self.headers (dict :Content-Type "application/json" :Authorization f"Bearer {api-key}"))
      (raise (RuntimeError "missing environment variable OPENAI_API_KEY")))
    (setv self.session None)
    (setv self.aiostd (AioStd)))

  (defm/a __aenter__ []
    (setv self.session (ClientSession))
    (<- (.__aenter__ self.session))
    (<- (.__aenter__ self.aiostd))
    self)

  (defm/a __aexit__ [exc-type exc-val exc-tb]
    (<- (.__aexit__ self.session exc-type exc-val exc-tb)))

  (defm/a __call__ []
    (while True
      (setv response (<- (self.get-response)))
      (setv got-tool-call False)
      (for [output (. response ["output"])]
        (cond
          (= (. output ["type"]) "message")
            ; just print and append to conversation, assuming len(content) = 1
            (do
              (setv resp-str (. output ["content"][0]["text"]))
              (<- (self.aiostd.send f"LLM: {resp-str}\n"))
              (.append self.messages {"role" "assistant" "content" resp-str}))
          (= (. output ["type"]) "function_call")
            (do
              (setv got-tool-call True)
              (.append self.messages output)
              (setv name (. output ["name"]) 
                    kwargs (json.loads (. output ["arguments"]))
                    func (. self.tools [name])
                    result (func #** kwargs))
              (when (isawaitable result)
                (setv result (<- result)))
              (<- (self.aiostd.send f"{name}({kwargs}) = {result}"))
              (.append self.messages {"type" "function_call_output" 
                                      "call_id" (. output ["call_id"]) 
                                      "output" (str result)}))
          True
            (raise (RuntimeError f"Unknown output type: {(. output ["type"])}"))))

      ; for now, disallow repeated tool calls
      (when got-tool-call
        (do
          (setv final-response (<- (self.get-response False)))
          (setv final-resp-str (. final-response ["output"][0]["content"][0]["text"]))
          (<- (self.aiostd.send f"LLM: {final-resp-str}\n"))
          (.append self.messages {"role" "assistant" "content" final-resp-str})))

      (setv user-line (.rstrip (<- (self.aiostd.recv))))
      (when (= user-line "")  ; EOF -> exit loop
        (break))
      (.append self.messages {"role" "user" "content" user-line})))

  (defm/a get-response [[tools True]]

    (setv payload {"model" self.model "input" self.messages})
    (when tools
      (setv (. payload ["tools"]) self.tools-schema))
    (.debug self.log "send payload[%s]" (json.dumps payload :indent 4))
    (with/a [resp (.post self.session self.endpoint
                                      :headers self.headers
                                      :json payload)]
      (.raise_for_status resp)
      (setv resp-json (<- (resp.json)))
      (.debug self.log "rcvd response[%s]" (json.dumps resp-json :indent 4))
      resp-json)))
