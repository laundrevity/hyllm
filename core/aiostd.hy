(import asyncio)
(import sys)

(require core.macros *)


(defclass AioStd []
  (defm __init__ []
    (setv self.reader None)
    (setv self.writer None))

  (defm/a __aenter__ []
    (setv self.reader (asyncio.StreamReader))
    (setv protocol (asyncio.StreamReaderProtocol self.reader))
    (setv loop (asyncio.get_running_loop))
    (setv [reader-transport _] (<- (loop.connect_read_pipe (fn [] protocol) sys.stdin)))
    (setv self.reader-transport reader-transport)

    (setv [writer-transport _] (<- (loop.connect_write_pipe (fn [] (asyncio.Protocol)) sys.stdout)))
    (setv self.writer-transport writer-transport)
    (setv self.writer (asyncio.StreamWriter writer-transport protocol self.reader loop))
    self)

  (defm/a __aexit__ [exc-type exc-val exc-tb]
    (.feed_eof self.reader)
    (.close self.reader-transport)
    (.close self.writer-transport))

  (defm/a recv []
    (<- (self.send "> "))
    (.decode (<- (.readline self.reader))))

  (defm/a send [msg]
    (.write self.writer (.encode msg))
    (<- (.drain self.writer))))
