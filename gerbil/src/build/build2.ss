;; -*- Gerbil -*-
    (import :gerbil/compiler)

    (extern namespace: "gerbil/core$<match>[:0:]" with)

    (def gerbil-modules-compiler
         '("gerbil/compiler/TEST.ss"))


    (step-level-set! 4)



     (displayln "In Build2" with)

    (def gerbil-libdir
       (path-expand "lib" (getenv "GERBIL_TARGET")))
    (def (compile1 modf debug optimize? gen-ssxi? static?)
      (displayln "\n\n------... compile " modf)
       (compile-file
         modf [
              output-dir: gerbil-libdir invoke-gsc: #t
              debug: debug optimize: optimize? generate-ssxi: gen-ssxi? static: static?
              gsc-options: ["-target" "js" "-module-ref" modf]]))
    (def (compile-group group . options)
      (for-each (lambda (x) (apply compile1 x options)) group))


  (def debug-none #f)  ; no bloat
  (def debug-src 'src) ; full introspection -- sadly, it adds bloat and increases load time


(compile-group gerbil-modules-compiler debug-none #f #t #f)
