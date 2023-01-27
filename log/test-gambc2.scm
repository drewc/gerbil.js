(displayln "This is a test for gx-gambc2: The compiler")
(define syns (read-syntax-from-file "./gx-version.scm"))
(display* "Have Syntax: " syns "which prints as\n\t")
(map _gx#pp-syntax syns)
(define (text-gvs) "0.17.0-666-hahaha")
(displayln "What is here? :" &context::t " and " _gx#eval
           "\n\tand finally " _gx#compile "in)
(display (map _gx#compile syns))
