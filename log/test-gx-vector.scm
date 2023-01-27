(displayln "This is a test for _gx#vector-* things")
 (define gxvec (##vector 1 2 42))
 (define gxstruct (##structure ##type-type 1 2 42))
 (define gxvals (##values 1 2 42))
 (define gxlist (list 1 2 3))
 (display*
  "Vector: " gxvec " answer " (_gx#vector-ref gxvec 2)
   " len " (_gx#vector-length gxvec))
 (display* "\n\tSet " (_gx#vector-set! gxvec 2 3))
 (display* "\n\t ->list equal to " gxlist "? "
  (equal? (_gx#vector->list gxvec) gxlist))
(display*
   "\n\nStruct: " gxstruct " answer " (_gx#vector-ref gxstruct 3)
    " len " (_gx#vector-length gxstruct))
(display* "\n\tSet " (_gx#vector-set! gxstruct 3 3))
 (display* "\n\t cdr ->list equal to " gxlist "? "
  (equal? (cdr (_gx#vector->list gxstruct)) gxlist))
(display*
 "\n\nValues: " gxvals " answer " (_gx#vector-ref gxvals 2)
 " len " (_gx#vector-length gxvals))
(display* "\n\tSet " (_gx#vector-set! gxvals 2 3))
(display* "\n\t  ->list equal to " gxlist "? "
 (equal? (_gx#vector->list gxvals) gxlist))
