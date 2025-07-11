(defmacro <- [awaitable]
    `(await ~awaitable))

(defmacro defn/a [name params #* body]
    `(defn :async ~name ~params ~@body))

(defmacro defm [name params #* body]
    `(defn ~name [self ~@params] ~@body))

(defmacro defm/a [name params #* body]
    `(defn :async ~name [self ~@params] ~@body))

(defmacro with/a [params #* body]
    `(with [:async ~@params] ~@body))
