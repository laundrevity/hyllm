(import decimal [Decimal :as deci])

(import aiohttp [ClientSession])

(import .toolkit [tool])

(require core.macros *)


(defmacro with/a [params #* body]
    `(with [:async ~@params] ~@body))


(defn/a [(tool "Get the current price of a spot pair from Coinbase" :pair "Pair of spot instruments, e.g. BTC-USD")]
  get-spot-pair-price [#^ str pair]
  (with/a [session (ClientSession)]
    (with/a [resp (.get session f"https://api.exchange.coinbase.com/products/{pair}/book")]
      (setv resp-json (<- (resp.json)))
      (setv bid (deci (. resp-json ["bids"][0][0]))
            ask (deci (. resp-json ["asks"][0][0]))
            mid (/ (+ bid ask) (deci 2)))
      mid)))
