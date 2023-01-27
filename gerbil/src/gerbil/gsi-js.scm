(##include "~~lib/header.scm")
(##include "~~gsi/_gsi.scm")

(define (%dummy arg . args)
  (##apply arg 1 args)
  (##apply arg 1 2 args)
  (##apply arg 1 2 3 args)
  (##apply arg 1 2 3 4 args)
  (##apply arg 1 2 3 4 5 args))
