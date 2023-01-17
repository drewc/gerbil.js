;;; The SRFI-32 sort package -- stable vector merge & merge sort -*- Scheme -*-
;;; Copyright (c) 1998 by Olin Shivers.
;;; This code is open-source; see the end of the file for porting and
;;; more copyright information.
;;; Olin Shivers 10/98.

;;; NEEDS A FINAL POLISH PASS; NOT READY FOR RELEASE.
;;; It works fine, but, e.g., the aux functions should be integrated inside
;;; the main top-level function to hide them.

;;; Exports:
;;; (vector-merge  v1 v2 < [start1 end1 start2 end2])          -> vector
;;; (vector-merge! v v1 v2 < [start0 start1 end1 start2 end2]) -> unspecific
;;;
;;; (vector-merge-sort  v < [start end temp]) -> vector
;;; (vector-merge-sort! v < [start end temp]) -> unspecific


;;; Merge
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; (vector-merge v1 v2 < [start1 end1 start2 end2]) -> vector
;;; (vector-merge! v v1 v2 < [start0 start1 end1 start2 end2]) -> unspecific
;;;
;;; Stable vector merge -- V1's elements come out ahead of equal V2 elements.

;; vyzo: unused and not exported
#;(define (vector-merge v1 v2 < . maybe-starts+ends)
  (let-optionals maybe-starts+ends ((start1 0) (end1 (vector-length v1))
				    (start2 0) (end2 (vector-length v2)))
    (let ((ans (make-vector (+ (- end1 start1) (- end2 start2)))))
      (%vector-merge! ans v1 v2 < 0 start1 end1 start2 end2)
      ans)))

#;(define (vector-merge! v v1 v2 < . maybe-starts+ends)
  (let-optionals maybe-starts+ends ((start0 0)
				    (start1 0) (end1 (vector-length v1))
				    (start2 0) (end2 (vector-length v2)))
    (%vector-merge! v v1 v2 < start0 start1 end1 start2 end2)))


;;; This routine is not exported. The code is tightly bummed.
;;;
;;; If these preconditions hold, the routine can be bummed to run with
;;; unsafe vector-indexing and fixnum arithmetic ops:
;;;   - V V1 V2 are vectors.
;;;   - START0 START1 END1 START2 END2 are fixnums.
;;;   - (<= 0 START0 END0 (vector-length V),
;;;     where end0 = start0 + (end1 - start1) + (end2 - start2)
;;;   - (<= 0 START1 END1 (vector-length V1))
;;;   - (<= 0 START2 END2 (vector-length V2))
;;; If you put these error checks in the two client procedures above, you can
;;; safely convert this procedure to use unsafe ops -- which is why it isn't
;;; exported. This will provide *huge* speedup.

(define (%vector-merge! v v1 v2 elt< start0 start1 end1 start2 end2)
  (letrec ((vblit (lambda (fromv j i end)      ; Blit FROMV[J,END) to V[I,?].
		    (let lp ((j j) (i i))
		      (vector-set! v i (vector-ref fromv j))
		      (let ((j (+ j 1)))
			(if (< j end) (lp j (+ i 1))))))))

    (cond ((<= end1 start1) (if (< start2 end2) (vblit v2 start2 start0 end2)))
	  ((<= end2 start2) (vblit v1 start1 start0 end1))

	  ;; Invariants: I is next index of V to write; X = V1[J]; Y = V2[K].
	  (else (let lp ((i start0)
			 (j start1)  (x (vector-ref v1 start1))
			 (k start2)  (y (vector-ref v2 start2)))
		  (let ((i1 (+ i 1)))	; "i+1" is a complex number in R4RS!
		    (if (elt< y x)
			(let ((k (+ k 1)))
			  (vector-set! v i y)
			  (if (< k end2)
			      (lp i1 j x k (vector-ref v2 k))
			      (vblit v1 j i1 end1)))
			(let ((j (+ j 1)))
			  (vector-set! v i x)
			  (if (< j end1) (vblit v2 k i1 end2)
			      (lp i1 j (vector-ref v1 j) k y))))))))))


;;; Stable sort
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; (vector-merge-sort  v < [start end temp]) -> vector
;;; (vector-merge-sort! v < [start end temp]) -> unspecific

#;(define (vector-merge-sort! v < . maybe-args)
  (let-optionals maybe-args ((start 0)
			     (end (vector-length v))
			     (temp (vector-copy v)))
    (%vector-merge-sort! v < start end temp)))

#;(define (vector-merge-sort v < . maybe-args)
  (let ((ans (vector-copy v)))
    (apply vector-merge-sort! ans < maybe-args)
    ans))

;;; %VECTOR-MERGE-SORT! is not exported.
;;; Preconditions:
;;;   V TEMP vectors
;;;   START END fixnums
;;;   START END legal indices for V and TEMP
;;; If these preconditions are ensured by the cover functions, you
;;; can safely change this code to use unsafe fixnum arithmetic and vector
;;; indexing ops, for *huge* speedup.

;;; This merge sort is "opportunistic" -- the leaves of the merge tree are
;;; contiguous runs of already sorted elements in the vector. In the best
;;; case -- an already sorted vector -- it runs in linear time. Worst case
;;; is still O(n lg n) time.
;;;
;;; RECUR: Sort V0[L,L+LEN) for some LEN where 0 < WANT <= LEN <= (R-L).
;;;   That is, sort *at least* WANT elements in V0 starting at index L.
;;;   May put the result into either V0[L,L+LEN) or TEMP0[L,L+LEN).
;;;   Must not alter either vector outside this range.
;;;   Return:
;;;     - LEN -- the number of values we sorted
;;;     - ANSVEC -- the vector holding the value
;;;     - ANS=V0? -- tells if ANSVEC is V0 or TEMP
;;;
;;; LP: V[L,L+PFXLEN) holds a sorted prefix of V0.
;;;     TEMP = if V = V0 then TEMP0 else V0. (I.e., TEMP is the other vec.)
;;;     PFXLEN2 is a power of 2 <= PFXLEN.
;;;     Solve RECUR's problem.

(define (%vector-merge-sort! v0 elt< l r temp0)
  (define (xor a b) (not (eq? a b)))
  (if (< l r) ; Don't try to sort an empty range.
      (receive (ignored-len ignored-ansvec ansvec=v0?)
	  (let recur ((l l) (want (- r l)))
	    (let ((len (- r l)))
	      (let lp ((pfxlen (getrun v0 l r elt<)) (pfxlen2 1)
		       (v v0) (temp temp0)
		       (v=v0? #t))
		(if (or (>= pfxlen want) (= pfxlen len))
		    (values pfxlen v v=v0?)
		    (let ((pfxlen2 (let lp ((j pfxlen2))
				     (let ((j*2 (+ j j)))
				       (if (<= j pfxlen) (lp j*2) j))))
			  (tail-len (- len pfxlen)))
		      ;; PFXLEN2 is now the largest power of 2 <= PFXLEN.
		      (receive (nr-len nr-vec nrvec=v0?)
			  (recur (+ pfxlen l) pfxlen2)
			(%vmerge temp v nr-vec l pfxlen nr-len
				 (xor nrvec=v0? v=v0?) elt<)
			(lp (+ pfxlen nr-len) (+ pfxlen2 pfxlen2)
			    temp v (not v=v0?))))))))
	(if (not ansvec=v0?) (vector-copy! v0 temp0 l r)))))

;;; Merge v1[l,l+len1) and v2[l+len1,l+len1+len2) into target[l,l+len1+len2)
;;; Merge left-to-right, so that TEMP may be either V1 or V2
;;; (that this is OK takes a little bit of thought).
;;; V2=TARGET? is true if V2 and TARGET are the same, which allows
;;; merge to punt the final blit half of the time.

(define (%vmerge target v1 v2 l len1 len2 v2=target? elt<)
  (letrec ((vblit (lambda (fromv j i end)    ; Blit FROMV[J,END) to TARGET[I,?]
		    (let lp ((j j) (i i))    ; J < END. The final copy.
		      (vector-set! target i (vector-ref fromv j))
		      (let ((j (+ j 1)))
			(if (< j end) (lp j (+ i 1))))))))

    (let* ((r1 (+ l  len1))
	   (r2 (+ r1 len2)))

      ;; Invariants: I is next index of TARGET to write; X = V1[J]; Y = V2[K].
      (let lp ((i l)
	       (j l)   (x (vector-ref v1 l))
	       (k r1)  (y (vector-ref v2 r1)))
	(let ((i1 (+ i 1)))		; "i+1" is a complex number in R4RS!
	  (if (elt< y x)
	      (let ((k (+ k 1)))
		(vector-set! target i y)
		(if (< k r2)
		    (lp i1 j x k (vector-ref v2 k))
		    (vblit v1 j i1 r1)))
	      (let ((j (+ j 1)))
		(vector-set! target i x)
		(if (< j r1) (lp i1 j (vector-ref v1 j) k y)
		    (if (not v2=target?) (vblit v2 k i1 r2))))))))))


;;; Might hack GETRUN so that if the run is short it pads it out to length
;;; 10 with insert sort...

;;; Precondition: l < r.
(define (getrun v l r elt<)
  (let lp ((i (+ l 1))  (x (vector-ref v l)))
    (if (>= i r) (- i l)
	(let ((y (vector-ref v i)))
	  (if (elt< y x) (- i l)
	      (lp (+ i 1) y))))))


;;; Copyright
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This code is
;;;     Copyright (c) 1998 by Olin Shivers.
;;; The terms are: You may do as you please with this code, as long as
;;; you do not delete this notice or hold me responsible for any outcome
;;; related to its use.
;;;
;;; Blah blah blah. Don't you think source files should contain more lines
;;; of code than copyright notice?


;;; Code tuning & porting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This is very portable code. It's R4RS with the following exceptions:
;;; - VECTOR-COPY
;;; - The scsh LET-OPTIONAL macro for parsing and defaulting optional
;;;   arguments.
;;; - The merge sort recursion bottoms out in a call to an insertion sort
;;;   routine, %INSERT-SORT!. But you could even punt this and go with pure
;;;   recursion in a pinch.
;;;
;;; This code is *tightly* bummed as far as I can go in portable Scheme.
;;;
;;; The two internal primitives that do the real work can be converted to
;;; use unsafe vector-indexing and fixnum-specific arithmetic ops *if* you
;;; alter the four small cover functions to enforce the invariants. This should
;;; provide *big* speedups. In fact, all the code bumming I've done pretty
;;; much disappears in the noise unless you have a good compiler and also
;;; can dump the vector-index checks and generic arithmetic -- so I've really
;;; just set things up for you to exploit.
;;;
;;; The optional-arg parsing, defaulting, and error checking is done with a
;;; portable R4RS macro. But if your Scheme has a faster mechanism (e.g.,
;;; Chez), you should definitely port over to it. Note that argument defaulting
;;; and error-checking are interleaved -- you don't have to error-check
;;; defaulted START/END args to see if they are fixnums that are legal vector
;;; indices for the corresponding vector, etc.
