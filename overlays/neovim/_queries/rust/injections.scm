; extends

(macro_invocation
  (scoped_identifier
    path: (identifier) @path (#eq? @path "sqlx")
    name: (identifier) @name (#match? @name "^query|query_as$")
    )
  (token_tree
    [
     (string_literal
       (string_content) @injection.content
       )
     (raw_string_literal
       (string_content) @injection.content
       )
     ]
    (#set! injection.language "sql")
    (#set! "priority" 128)
    )
  )

(call_expression
  (scoped_identifier
    path: (identifier) @path (#eq? @path "sqlx")
    name: (identifier) @name (#match? @name "^query|query_as$")
    )
  (arguments
    [
     (string_literal
       (string_content) @injection.content
       )
     (raw_string_literal
       (string_content) @injection.content
       )
     ]
    (#set! injection.language "sql")
    (#set! "priority" 128)
    )
  )
