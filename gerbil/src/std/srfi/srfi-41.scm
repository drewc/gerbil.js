; Copyright (C) 2007 by Philip L. Bewig of Saint Louis, Missouri, USA.  All rights
; reserved.  Permission is hereby granted, free of charge, to any person obtaining a copy of
; this software and associated documentation files (the "Software"), to deal in the Software
; without restriction, including without limitation the rights to use, copy, modify, merge,
; publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
; whom the Software is furnished to do so, subject to the following conditions: The above
; copyright notice and this permission notice shall be included in all copies or substantial
; portions of the Software.  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
; FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
; CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
; THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SRFI-9 records

;; (define-syntax define-record-type
;;   (syntax-rules ()
;;     ((define-record-type type
;;        (constructor constructor-tag ...)
;;        predicate
;;        (field-tag accessor . more) ...)
;;      (begin
;;        (define type
;;          (make-record-type 'type '(field-tag ...)))
;;        (define constructor
;;          (record-constructor type '(constructor-tag ...)))
;;        (define predicate
;;          (record-predicate type))
;;        (define-record-field type field-tag accessor . more)
;;        ...))))

;; (define-syntax define-record-field
;;   (syntax-rules ()
;;     ((define-record-field type field-tag accessor)
;;      (define accessor (record-accessor type 'field-tag)))
;;     ((define-record-field type field-tag accessor modifier)
;;      (begin
;;        (define accessor (record-accessor type 'field-tag))
;;        (define modifier (record-modifier type 'field-tag))))))

;; (define record-marker (list 'record-marker))

;; (define real-vector? vector?)

;; (define (vector? x)
;;   (and (real-vector? x)
;;        (or (= 0 (vector-length x))
;; 	   (not (eq? (vector-ref x 0)
;; 		record-marker)))))

;; (define eval
;;   (let ((real-eval eval))
;;     (lambda (exp env)
;;       ((real-eval `(lambda (vector?) ,exp))
;;        vector?))))

;; (define (record? x)
;;   (and (real-vector? x)
;;        (< 0 (vector-length x))
;;        (eq? (vector-ref x 0)
;;             record-marker)))

;; (define (make-record size)
;;   (let ((new (make-vector (+ size 1))))
;;     (vector-set! new 0 record-marker)
;;     new))

;; (define (record-ref record index)
;;   (vector-ref record (+ index 1)))

;; (define (record-set! record index value)
;;   (vector-set! record (+ index 1) value))

;; (define (record-type record)
;;   (record-ref record 0))

;; (define :record-type (make-record 3))
;; (record-set! :record-type 0 :record-type)
;; (record-set! :record-type 1 ':record-type)
;; (record-set! :record-type 2 '(name field-tags))

;; (define (make-record-type name field-tags)
;;   (let ((new (make-record 3)))
;;     (record-set! new 0 :record-type)
;;     (record-set! new 1 name)
;;     (record-set! new 2 field-tags)
;;     new))

;; (define (record-type-name record-type)
;;   (record-ref record-type 1))

;; (define (record-type-field-tags record-type)
;;   (record-ref record-type 2))

;; (define (field-index type tag)
;;   (let loop ((i 1) (tags (record-type-field-tags type)))
;;     (cond ((null? tags)
;;            (error 'field-index "record type has no such field" type tag))
;;           ((eq? tag (car tags))
;;            i)
;;           (else
;;            (loop (+ i 1) (cdr tags))))))

;; (define (record-constructor type tags)
;;   (let ((size (length (record-type-field-tags type)))
;;         (arg-count (length tags))
;;         (indexes (map (lambda (tag)
;;                         (field-index type tag))
;;                       tags)))
;;     (lambda args
;;       (if (= (length args)
;;              arg-count)
;;           (let ((new (make-record (+ size 1))))
;;             (record-set! new 0 type)
;;             (for-each (lambda (arg i)
;; 			(record-set! new i arg))
;;                       args
;;                       indexes)
;;             new)
;;           (error 'record-constructor "wrong number of arguments to constructor" type args)))))

;; (define (record-predicate type)
;;   (lambda (thing)
;;     (and (record? thing)
;;          (eq? (record-type thing)
;;               type))))

;; (define (record-accessor type tag)
;;   (let ((index (field-index type tag)))
;;     (lambda (thing)
;;       (if (and (record? thing)
;;                (eq? (record-type thing)
;;                     type))
;;           (record-ref thing index)
;;           (error 'record-accessor "accessor applied to bad value" type tag thing)))))

;; (define (record-modifier type tag)
;;   (let ((index (field-index type tag)))
;;     (lambda (thing value)
;;       (if (and (record? thing)
;;                (eq? (record-type thing)
;;                     type))
;;           (record-set! thing index value)
;;           (error 'record-modifier "modifier applied to bad value" type tag thing)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SRFI-23 errors (modified for R6RS)

;; (define (error reason . args)
;;   (display "Error: ")
;;   (display (symbol->string reason))
;;   (for-each (lambda (arg)
;;             (display " ")
;;             (write arg))
;;             args)
;;   (newline)
;;   (scheme-report-environment -1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; (streams primitive)

  (define-record-type stream-type
    (make-stream box)
    stream?
    (box stream-promise stream-promise!))

  (define-syntax stream-lazy
    (syntax-rules ()
      ((stream-lazy expr)
        (make-stream
          (cons 'lazy (lambda () expr))))))

  (define (stream-eager expr)
    (make-stream
      (cons 'eager expr)))

  (define-syntax stream-delay
    (syntax-rules ()
      ((stream-delay expr)
        (stream-lazy (stream-eager expr)))))

  (define (stream-force promise)
    (let ((content (stream-promise promise)))
      (case (car content)
        ((eager) (cdr content))
        ((lazy)  (let* ((promise* ((cdr content)))
                        (content  (stream-promise promise)))
                   (if (not (eqv? (car content) 'eager))
                       (begin (set-car! content (car (stream-promise promise*)))
                              (set-cdr! content (cdr (stream-promise promise*)))
                              (stream-promise! promise* content)))
                   (stream-force promise))))))

  (define stream-null (stream-delay (cons 'stream 'null)))

  (define-record-type stream-pare-type
    (make-stream-pare kar kdr)
    stream-pare?
    (kar stream-kar)
    (kdr stream-kdr))

  (define (stream-pair? obj)
    (and (stream? obj) (stream-pare? (stream-force obj))))

  (define (stream-null? obj)
    (and (stream? obj)
         (eqv? (stream-force obj)
               (stream-force stream-null))))

  (define-syntax stream-cons
    (syntax-rules ()
      ((stream-cons obj strm)
        (stream-eager (make-stream-pare (stream-delay obj) (stream-lazy strm))))))

  (define (stream-car strm)
    (cond ((not (stream? strm)) (error 'stream-car "non-stream"))
          ((stream-null? strm) (error 'stream-car "null stream"))
          (else (stream-force (stream-kar (stream-force strm))))))

  (define (stream-cdr strm)
    (cond ((not (stream? strm)) (error 'stream-cdr "non-stream"))
          ((stream-null? strm) (error 'stream-cdr "null stream"))
          (else (stream-kdr (stream-force strm)))))

  (define-syntax stream-lambda
    (syntax-rules ()
      ((stream-lambda formals body0 body1 ...)
        (lambda formals (stream-lazy (let () body0 body1 ...))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; (streams derived)

  (define (exists pred? . lists)
    (and (not (null? (car lists)))
         (or (apply pred? (map car lists))
             (apply exists pred? (map cdr lists)))))

  (define-syntax define-stream
    (syntax-rules ()
      ((define-stream (name . formal) body0 body1 ...)
        (define name (stream-lambda formal body0 body1 ...)))))

  (define (list->stream objs)
    (define list->stream
      (stream-lambda (objs)
        (if (null? objs)
            stream-null
            (stream-cons (car objs) (list->stream (cdr objs))))))
    (if (not (list? objs))
        (error 'list->stream "non-list argument")
        (list->stream objs)))

  (define (port->stream . port)
    (define port->stream
      (stream-lambda (p)
        (let ((c (read-char p)))
          (if (eof-object? c)
              stream-null
              (stream-cons c (port->stream p))))))
    (let ((p (if (null? port) (current-input-port) (car port))))
      (if (not (input-port? p))
          (error 'port->stream "non-input-port argument")
          (port->stream p))))

  (define-syntax stream
    (syntax-rules ()
      ((stream) stream-null)
      ((stream x y ...) (stream-cons x (stream y ...)))))

  (define (stream->list . args)
    (let ((n (if (= 1 (length args)) #f (car args)))
          (strm (if (= 1 (length args)) (car args) (cadr args))))
      (cond ((not (stream? strm)) (error 'stream->list "non-stream argument"))
            ((and n (not (integer? n))) (error 'stream->list "non-integer count"))
            ((and n (negative? n)) (error 'stream->list "negative count"))
            (else (let loop ((n (if n n -1)) (strm strm))
                    (if (or (zero? n) (stream-null? strm))
                        '()
                        (cons (stream-car strm) (loop (- n 1) (stream-cdr strm)))))))))

  (define (stream-append . strms)
    (define stream-append
      (stream-lambda (strms)
        (cond ((null? (cdr strms)) (car strms))
              ((stream-null? (car strms)) (stream-append (cdr strms)))
              (else (stream-cons (stream-car (car strms))
                                 (stream-append (cons (stream-cdr (car strms)) (cdr strms))))))))
    (cond ((null? strms) stream-null)
          ((exists (lambda (x) (not (stream? x))) strms)
            (error 'stream-append "non-stream argument"))
          (else (stream-append strms))))

  (define (stream-concat strms)
    (define stream-concat
      (stream-lambda (strms)
        (cond ((stream-null? strms) stream-null)
              ((not (stream? (stream-car strms)))
                (error 'stream-concat "non-stream object in input stream"))
              ((stream-null? (stream-car strms))
                (stream-concat (stream-cdr strms)))
              (else (stream-cons
                      (stream-car (stream-car strms))
                      (stream-concat
                        (stream-cons (stream-cdr (stream-car strms)) (stream-cdr strms))))))))
    (if (not (stream? strms))
        (error 'stream-concat "non-stream argument")
        (stream-concat strms)))

  (define stream-constant
    (stream-lambda objs
      (cond ((null? objs) stream-null)
            ((null? (cdr objs)) (stream-cons (car objs) (stream-constant (car objs))))
            (else (stream-cons (car objs)
                               (apply stream-constant (append (cdr objs) (list (car objs)))))))))

  (define (stream-drop n strm)
    (define stream-drop
      (stream-lambda (n strm)
        (if (or (zero? n) (stream-null? strm))
            strm
            (stream-drop (- n 1) (stream-cdr strm)))))
    (cond ((not (integer? n)) (error 'stream-drop "non-integer argument"))
          ((negative? n) (error 'stream-drop "negative argument"))
          ((not (stream? strm)) (error 'stream-drop "non-stream argument"))
          (else (stream-drop n strm))))

  (define (stream-drop-while pred? strm)
    (define stream-drop-while
      (stream-lambda (strm)
        (if (and (stream-pair? strm) (pred? (stream-car strm)))
            (stream-drop-while (stream-cdr strm))
            strm)))
    (cond ((not (procedure? pred?)) (error 'stream-drop-while "non-procedural argument"))
          ((not (stream? strm)) (error 'stream-drop-while "non-stream argument"))
          (else (stream-drop-while strm))))

  (define (stream-filter pred? strm)
    (define stream-filter
      (stream-lambda (strm)
        (cond ((stream-null? strm) stream-null)
              ((pred? (stream-car strm))
                (stream-cons (stream-car strm) (stream-filter (stream-cdr strm))))
              (else (stream-filter (stream-cdr strm))))))
    (cond ((not (procedure? pred?)) (error 'stream-filter "non-procedural argument"))
          ((not (stream? strm)) (error 'stream-filter "non-stream argument"))
          (else (stream-filter strm))))

  (define (stream-fold proc base strm)
    (cond ((not (procedure? proc)) (error 'stream-fold "non-procedural argument"))
          ((not (stream? strm)) (error 'stream-fold "non-stream argument"))
          (else (let loop ((base base) (strm strm))
                  (if (stream-null? strm)
                      base
                      (loop (proc base (stream-car strm)) (stream-cdr strm)))))))

  (define (stream-for-each proc . strms)
    (define (stream-for-each strms)
      (if (not (exists stream-null? strms))
          (begin (apply proc (map stream-car strms))
                 (stream-for-each (map stream-cdr strms)))))
    (cond ((not (procedure? proc)) (error 'stream-for-each "non-procedural argument"))
          ((null? strms) (error 'stream-for-each "no stream arguments"))
          ((exists (lambda (x) (not (stream? x))) strms)
            (error 'stream-for-each "non-stream argument"))
          (else (stream-for-each strms))))

  (define (stream-from first . step)
    (define stream-from
      (stream-lambda (first delta)
        (stream-cons first (stream-from (+ first delta) delta))))
    (let ((delta (if (null? step) 1 (car step))))
      (cond ((not (number? first)) (error 'stream-from "non-numeric starting number"))
            ((not (number? delta)) (error 'stream-from "non-numeric step size"))
            (else (stream-from first delta)))))

  (define (stream-iterate proc base)
    (define stream-iterate
      (stream-lambda (base)
        (stream-cons base (stream-iterate (proc base)))))
    (if (not (procedure? proc))
        (error 'stream-iterate "non-procedural argument")
        (stream-iterate base)))

  (define (stream-length strm)
    (if (not (stream? strm))
        (error 'stream-length "non-stream argument")
        (let loop ((len 0) (strm strm))
          (if (stream-null? strm)
              len
              (loop (+ len 1) (stream-cdr strm))))))

  (define-syntax stream-let
    (syntax-rules ()
      ((stream-let tag ((name val) ...) body1 body2 ...)
       ((letrec ((tag (stream-lambda (name ...) body1 body2 ...))) tag) val ...))))

  (define (stream-map proc . strms)
    (define stream-map
      (stream-lambda (strms)
        (if (exists stream-null? strms)
            stream-null
            (stream-cons (apply proc (map stream-car strms))
                         (stream-map (map stream-cdr strms))))))
    (cond ((not (procedure? proc)) (error 'stream-map "non-procedural argument"))
          ((null? strms) (error 'stream-map "no stream arguments"))
          ((exists (lambda (x) (not (stream? x))) strms)
            (error 'stream-map "non-stream argument"))
          (else (stream-map strms))))

  (define-syntax stream-match
    (syntax-rules ()
      ((stream-match strm-expr clause ...)
        (let ((strm strm-expr))
          (cond
            ((not (stream? strm)) (error 'stream-match "non-stream argument"))
            ((stream-match-test strm clause) => car) ...
            (else (error 'stream-match "pattern failure")))))))

  (define-syntax stream-match-test
    (syntax-rules ()
      ((stream-match-test strm (pattern fender expr))
        (stream-match-pattern strm pattern () (and fender (list expr))))
      ((stream-match-test strm (pattern expr))
        (stream-match-pattern strm pattern () (list expr)))))

  (define-syntax stream-match-pattern
    (lambda (x)
      (define (wildcard? x)
        (and (identifier? x)
             (free-identifier=? x (syntax _))))
      (syntax-case x ()
        ((stream-match-pattern strm () (binding ...) body)
          (syntax (and (stream-null? strm) (let (binding ...) body))))
        ((stream-match-pattern strm (w? . rest) (binding ...) body)
          (wildcard? #'w?)
          (syntax (and (stream-pair? strm)
                       (let ((strm (stream-cdr strm)))
                         (stream-match-pattern strm rest (binding ...) body)))))
        ((stream-match-pattern strm (var . rest) (binding ...) body)
          (syntax (and (stream-pair? strm)
                       (let ((temp (stream-car strm)) (strm (stream-cdr strm)))
                         (stream-match-pattern strm rest ((var temp) binding ...) body)))))
        ((stream-match-pattern strm w? (binding ...) body)
          (wildcard? #'w?)
          (syntax (let (binding ...) body)))
        ((stream-match-pattern strm var (binding ...) body)
          (syntax (let ((var strm) binding ...) body))))))

  (define-syntax stream-of
    (syntax-rules ()
      ((stream-of expr rest ...)
        (stream-of-aux expr stream-null rest ...))))

  (define-syntax stream-of-aux
    (syntax-rules (in is)
      ((stream-of-aux expr base)
        (stream-cons expr base))
      ((stream-of-aux expr base (var in stream) rest ...)
        (stream-let loop ((strm stream))
          (if (stream-null? strm)
              base
              (let ((var (stream-car strm)))
                (stream-of-aux expr (loop (stream-cdr strm)) rest ...)))))
      ((stream-of-aux expr base (var is exp) rest ...)
        (let ((var exp)) (stream-of-aux expr base rest ...)))
      ((stream-of-aux expr base pred? rest ...)
        (if pred? (stream-of-aux expr base rest ...) base))))

  (define (stream-range first past . step)
    (define stream-range
      (stream-lambda (first past delta lt?)
        (if (lt? first past)
            (stream-cons first (stream-range (+ first delta) past delta lt?))
            stream-null)))
    (cond ((not (number? first)) (error 'stream-range "non-numeric starting number"))
          ((not (number? past)) (error 'stream-range "non-numeric ending number"))
          (else (let ((delta (cond ((pair? step) (car step)) ((< first past) 1) (else -1))))
                  (if (not (number? delta))
                      (error 'stream-range "non-numeric step size")
                      (let ((lt? (if (< 0 delta) < >)))
                        (stream-range first past delta lt?)))))))

  (define (stream-ref strm n)
    (cond ((not (stream? strm)) (error 'stream-ref "non-stream argument"))
          ((not (integer? n)) (error 'stream-ref "non-integer argument"))
          ((negative? n) (error 'stream-ref "negative argument"))
          (else (let loop ((strm strm) (n n))
                  (cond ((stream-null? strm) (error 'stream-ref "beyond end of stream"))
                        ((zero? n) (stream-car strm))
                        (else (loop (stream-cdr strm) (- n 1))))))))

  (define (stream-reverse strm)
    (define stream-reverse
      (stream-lambda (strm rev)
        (if (stream-null? strm)
            rev
            (stream-reverse (stream-cdr strm) (stream-cons (stream-car strm) rev)))))
    (if (not (stream? strm))
        (error 'stream-reverse "non-stream argument")
        (stream-reverse strm stream-null)))

  (define (stream-scan proc base strm)
    (define stream-scan
      (stream-lambda (base strm)
        (if (stream-null? strm)
            (stream base)
            (stream-cons base (stream-scan (proc base (stream-car strm)) (stream-cdr strm))))))
    (cond ((not (procedure? proc)) (error 'stream-scan "non-procedural argument"))
          ((not (stream? strm)) (error 'stream-scan "non-stream argument"))
          (else (stream-scan base strm))))

  (define (stream-take n strm)
    (define stream-take
      (stream-lambda (n strm)
        (if (or (stream-null? strm) (zero? n))
            stream-null
            (stream-cons (stream-car strm) (stream-take (- n 1) (stream-cdr strm))))))
    (cond ((not (stream? strm)) (error 'stream-take "non-stream argument"))
          ((not (integer? n)) (error 'stream-take "non-integer argument"))
          ((negative? n) (error 'stream-take "negative argument"))
          (else (stream-take n strm))))

  (define (stream-take-while pred? strm)
    (define stream-take-while
      (stream-lambda (strm)
        (cond ((stream-null? strm) stream-null)
              ((pred? (stream-car strm))
                (stream-cons (stream-car strm) (stream-take-while (stream-cdr strm))))
              (else stream-null))))
    (cond ((not (stream? strm)) (error 'stream-take-while "non-stream argument"))
          ((not (procedure? pred?)) (error 'stream-take-while "non-procedural argument"))
          (else (stream-take-while strm))))

  (define (stream-unfold mapper pred? generator base)
    (define stream-unfold
      (stream-lambda (base)
        (if (pred? base)
            (stream-cons (mapper base) (stream-unfold (generator base)))
            stream-null)))
    (cond ((not (procedure? mapper)) (error 'stream-unfold "non-procedural mapper"))
          ((not (procedure? pred?)) (error 'stream-unfold "non-procedural pred?"))
          ((not (procedure? generator)) (error 'stream-unfold "non-procedural generator"))
          (else (stream-unfold base))))

  (define (stream-unfolds gen seed)
    (define (len-values gen seed)
      (call-with-values
        (lambda () (gen seed))
        (lambda vs (- (length vs) 1))))
    (define unfold-result-stream
      (stream-lambda (gen seed)
        (call-with-values
          (lambda () (gen seed))
          (lambda (next . results)
            (stream-cons results (unfold-result-stream gen next))))))
    (define result-stream->output-stream
      (stream-lambda (result-stream i)
        (let ((result (list-ref (stream-car result-stream) (- i 1))))
          (cond ((pair? result)
                  (stream-cons
                    (car result)
                    (result-stream->output-stream (stream-cdr result-stream) i)))
                ((not result)
                  (result-stream->output-stream (stream-cdr result-stream) i))
                ((null? result) stream-null)
                (else (error 'stream-unfolds "can't happen"))))))
    (define (result-stream->output-streams result-stream)
      (let loop ((i (len-values gen seed)) (outputs '()))
        (if (zero? i)
            (apply values outputs)
            (loop (- i 1) (cons (result-stream->output-stream result-stream i) outputs)))))
    (if (not (procedure? gen))
        (error 'stream-unfolds "non-procedural argument")
        (result-stream->output-streams (unfold-result-stream gen seed))))

  (define (stream-zip . strms)
    (define stream-zip
      (stream-lambda (strms)
        (if (exists stream-null? strms)
            stream-null
            (stream-cons (map stream-car strms) (stream-zip (map stream-cdr strms))))))
    (cond ((null? strms) (error 'stream-zip "no stream arguments"))
          ((exists (lambda (x) (not (stream? x))) strms)
            (error 'stream-zip "non-stream argument"))
          (else (stream-zip strms))))
