(import inspect)
(import pathlib [Path])
(import importlib.util)

(setv *PYTHON-TO-JSON-TYPE* {"int" "integer"
                             "float" "number"
                             "bool" "boolean"
                             "list" "array"
                             "dict" "object"
                             "str" "string"})

(defn tool [description #** arg-descriptions]
  #_"Decorator for generating tool JSON schema"
  (defn inner [func]
    (setv schema {"type" "function"
                  "name" func.__name__
                  "description" description
                  "parameters" {"type" "object" 
                                "properties" {}
                                "required" []
                                "additionalProperties" False}
                    "strict" True})

    (setv descriptions (list (arg-descriptions.values)))
    (setv annotations (list (.values (. (inspect.signature func) parameters))))

    (for [#(desc anno) (list (zip descriptions annotations))]
      (setv (. schema ["parameters"]["properties"][anno.name]) {"type" (get *PYTHON-TO-JSON-TYPE* (. anno.annotation __name__)) 
                                                                "description" desc})
      (.append (. schema ["parameters"]["required"]) anno.name))
    (setv (. func schema) schema)
    func)

  inner)

(defn gather-toolkit []
  (setv schemas [])
  (setv tools {})
  (setv current-file (. (Path __file__) name)
        current-dir (. (Path __file__) parent))
  (for [hy-file (current-dir.glob "*.hy")]
    (when (= hy-file.name current-file)
      (continue))

    (setv rel-path (.relative-to hy-file (Path.cwd)))
    (setv module-name (+ "tools." hy-file.stem))
    (setv spec (.spec-from-file-location importlib.util module-name hy-file))

    (setv module (.module-from-spec importlib.util spec))
    (.exec-module spec.loader module)

    ; find functions with a .schema attribute
    (for [#(name obj) (.items (vars module))]
      (when (and (or (inspect.isfunction obj) (inspect.iscoroutinefunction obj)) (hasattr obj "schema"))
        (schemas.append obj.schema)
        (setv (. tools [name]) obj))))
  #(schemas tools))
