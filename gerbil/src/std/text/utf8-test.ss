;;; -*- Gerbil -*-
;;; (C) vyzo at hackzen.org
;;; :std/text/utf8 unit test

(import :std/test
        :std/text/utf8
        :std/sugar
	:std/error
        :gerbil/gambit/random
        :gerbil/gambit/exceptions)

(export utf8-test)

(def (error-with-message? message)
  (lambda (e)
    (and (error-exception? e) (equal? (error-exception-message e) message))))

(def utf8-test
  (test-suite "test :std/text/utf8"

    (def (check-encode-decode str)
      (let (p (string->utf8 str))
        (check (utf8->string p) => str)))

    (test-case "test utf8 encoding and decoding of random strings"
      (def N 10)
      (def len 100)
      (def Q (+ ##max-char 1))
      (def (get-random-char)
        (try
         (integer->char (random-integer Q))
         (catch (range-exception? e)
           (get-random-char))))
      (let lp ((k 0))
        (when (fx< k N)
          (let (str (make-string len))
            (let lp2 ((i 0))
              (when (fx< i len)
                (string-set! str i (get-random-char))
                (lp2 (fx1+ i))))
            (check-encode-decode str)
            (lp (fx1+ k))))))

    (test-case "test utf8 encoding and decoding malformed inputs"
      (check-exception (string->utf8 #f) (error-with-message? "Bad argument; expected string"))
      (check-exception (string-utf8-length #f) (error-with-message? "Bad argument; expected string"))
      (check-exception (utf8->string #f) (error-with-message? "Bad argument; expected u8vector")))
    ))
