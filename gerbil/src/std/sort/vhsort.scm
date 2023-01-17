;;; The SRFI-?? sort package -- vector heap sort		-*- Scheme -*-
;;; Copyright (c) 2002 by Olin Shivers.
;;; This code is open-source; see the end of the file for porting and
;;; more copyright information.
;;; Olin Shivers 10/98.

;;; Exports:
;;; (heap-sort! v elt< [start end]) -> unspecified
;;; (heap-sort  v elt< [start end]) -> vector

;;; Two key facts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; If a heap structure is embedded into a vector at indices [start,end), then:
;;;   1. The two children of index k are start + 2*(k-start) + 1 = k*2-start+1
;;;                                  and start + 2*(k-start) + 2 = k*2-start+2.
;;;
;;;   2. The first index of a leaf node in the range [start,end) is
;;;          first-leaf = floor[(start+end)/2]
;;;      (You can deduce this from fact #1 above.)
;;;      Any index before FIRST-LEAF is an internal node.

(define (really-heap-sort! v elt< start end)
  ;; Vector V contains a heap at indices [START,END). The heap is in heap
  ;; order in the range (I,END) -- i.e., every element in this range is >=
  ;; its children. Bubble HEAP[I] down into the heap to impose heap order on
  ;; the range [I,END).
  (define (restore-heap! end i)
    (let* ((vi (vector-ref v i))
	   (first-leaf (quotient (+ start end) 2)) ; Can fixnum overflow.
	   (final-k (let lp ((k i))
		      (if (>= k first-leaf) k ; Leaf, so done.
			  (let* ((k*2-start (+ k (- k start))) ; Don't overflow.
				 (child1 (+ 1 k*2-start))
				 (child2 (+ 2 k*2-start))
				 (child1-val (vector-ref v child1)))
			    (receive (max-child max-child-val)
				(if (< child2 end)
				    (let ((child2-val (vector-ref v child2)))
				      (if (elt< child2-val child1-val)
					  (values child1 child1-val)
					  (values child2 child2-val)))
				    (values child1 child1-val))
			      (cond ((elt< vi max-child-val)
				     (vector-set! v k max-child-val)
				     (lp max-child))
				    (else k)))))))) ; Done.
      (vector-set! v final-k vi)))

  ;; Put the unsorted subvector V[start,end) into heap order.
  (let ((first-leaf (quotient (+ start end) 2)))  ; Can fixnum overflow.
    (do ((i (- first-leaf 1) (- i 1)))
	((< i 0))
      (restore-heap! end i)))

  (do ((i (- end 1) (- i 1)))
      ((<= i 0))
    (let ((top (vector-ref v start)))
      (vector-set! v start (vector-ref v i))
      (vector-set! v i top)
      (restore-heap! i start))))

;;; Here are the two exported interfaces.

(define (heap-sort! v elt< . maybe-start+end)
  (let-vector-start+end (start end) heap-sort! v maybe-start+end
    (really-heap-sort! v elt< start end)))

(define (heap-sort v elt< . maybe-start+end)
  (let-vector-start+end (start end) heap-sort v maybe-start+end
    (let ((ans (vector-copy v start end)))
      (really-heap-sort! ans elt< 0 (- end start))
      ans)))

;;; Notes on porting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This code is completely R5RS-compliant, with two exceptions:
;;; + (RECEIVE (var ...) mv-exp body ...)
;;;   This is the SRFI-?? multiple-value form that expands into
;;;   (call-with-values (lambda () mv-exp) (lambda (var ...) body ...))
;;;
;;; + (LET-VECTOR-START+END (start end) client-proc v maybe-start+end body ...)
;;;   This macro defaults & checks the optional START/END subvector arguments
;;;   passed to HEAP-SORT and HEAP-SORT!.
;;;
;;; Both of these macros are defined in a separate file sort-support-macs.scm
;;; that comes with the SRFI-?? reference implementation.
;;;
;;; Bumming the code for speed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; If you can use a module system to lock up the internal function
;;; REALLY-HEAP-SORT! so that it can only be called from HEAP-SORT and
;;; HEAP-SORT!, then you can hack the internal functions to run with no safety
;;; checks. The safety checks performed by the exported functions HEAP-SORT &
;;; HEAP-SORT! guarantee that there will be no type errors or array-indexing
;;; errors. In addition, with the exception of the two computations of
;;; FIRST-LEAF, all arithmetic will be fixnum arithmetic that never overflows
;;; into bignums, assuming your Scheme provides that you can't allocate an
;;; array so large you might need a bignum to index an element, which is
;;; definitely the case for every implementation with which I am familiar.
;;;
;;; If you want to code up the first-leaf = (quotient (+ s e) 2) computation
;;; so that it will never fixnum overflow when S & E are fixnums, you can do
;;; it this way:
;;;   - compute floor(e/2), which throws away e's low-order bit.
;;;   - add e's low-order bit to s, and divide that by two:
;;;     floor[(s + e mod 2) / 2]
;;;   - add these two parts together.
;;; giving you
;;;   (+ (quotient e 2)
;;;      (quotient (+ s (modulo e 2)) 2))
;;; If we know that e & s are fixnums, and that 0 <= s <= e, then this
;;; can only fixnum-overflow when s = e = max-fixnum. Note that the
;;; two divides and one modulo op can be done very quickly with two
;;; right-shifts and a bitwise and.
;;;
;;; I suspect there has never been a heapsort written in the history of
;;; the world in C that got this detail right.
;;;
;;; If your Scheme has a faster mechanism for handling optional arguments
;;; (e.g., Chez), you should definitely port over to it. Note that argument
;;; defaulting and error-checking are interleaved -- you don't have to
;;; error-check defaulted START/END args to see if they are fixnums that are
;;; legal vector indices for the corresponding vector, etc.
