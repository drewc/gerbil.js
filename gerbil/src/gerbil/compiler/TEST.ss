;;; -*- Gerbil -*-
;;; (C) vyzo at hackzen.org
;;; gerbil compiler optimization passes
package: gerbil/compiler
namespace: gxc

(import :gerbil/expander
        "base"
        "compile"
        "optimize-base"
        "optimize-xform")
(export #t)

  (def (optimize-match-body stx negation clauses konts)
  (def (push-variables clause kont)
    (with (([clause-name . clause-lambda] clause)
           ([FOO . UNDERSCOREFOO] kont)
           ) ;; This is line 101
      (cons clause-name (apply-push-match-vars clause-lambda [] BAR))))

  (def (start-match kont)
    (ast-case kont (%#lambda)
      ((%#lambda () body) #'body)))

  (def (match-body blocks)
    (with ([[#f . start] . rest] blocks)
      (let lp ((rest rest) (body (start-match start)))
        (match rest
          ([block . rest]
           (with ([BAZ . kont] block)
             (lp rest ['%#let-values [[[BAZ] kont]] body])))
          (else body)))))

  (parameterize ((current-expander-context (make-local-context)))
    (let* ((clauses (map push-variables clauses konts))
                                          ;         (blocks (optimize-match-basic-blocks clauses))
                                          ;        (blocks (optimize-match-fold-basic-blocks blocks))
                                          ;       (body (match-body blocks))
                                          ;      (bind (map (match <> ([K . kont] [[K] kont]))
           ;; konts
                                          ; ))
           #;     (negate (with ([K . kont] negation) [[K] kont]))
           )
      #;(xform-wrap-source
       ['%#let-values [negate]
         ['%#let-values bind body]]
       stx)

  clauses)))
