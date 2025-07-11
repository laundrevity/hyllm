(import asyncio)

(import click)

(import core.agent [Agent])

(require core.macros *)

(defn/a run-agent [prompt model log-level]
  (with/a [agent (Agent prompt model log-level)]
    (<- (agent))))

(defn [(click.command) 
       (click.option "--prompt" "-p" :help "User prompt" :show_default True :default "what is 2+2?")
       (click.option "--model" "-m" :help "model" :show_default True :default "gpt-4.1-nano")
       (click.option "--log-level" "-l" :help "log level" :show_default True :default "INFO")]
      cli [prompt model log-level]
        (asyncio.run (run-agent prompt model log-level)))


(when (= __name__ "__main__")
  (cli))
