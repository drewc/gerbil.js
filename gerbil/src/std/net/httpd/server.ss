;;; -*- Gerbil -*-
;;; (C) vyzo
;;; embedded HTTP/1.1 server

(import :gerbil/gambit/threads
        :gerbil/gambit/exceptions
        :std/net/httpd/handler
        :std/net/httpd/mux
        :std/net/socket
        :std/os/socket
        :std/actor/message
        :std/actor/proto
        :std/misc/threads
        :std/logger
        :std/sugar)
(export start-http-server!
        stop-http-server!
        http-register-handler
        current-http-server)

(deflogger httpd)

(defproto httpd
  (register host path handler)
  event:
  (join thread)
  (shutdown))

(def current-http-server
  (make-parameter #f))

(def (start-http-server! mux: (mux (make-default-http-mux))
                         backlog: (backlog 10)
                         sockopts: (sockopts [SO_REUSEADDR])
                         . addresses)
  (start-logger!)
  (let* ((sas (map socket-address addresses))
         (socks (map (cut ssocket-listen <> backlog sockopts) sas)))
    (spawn/group 'http-server http-server socks sas mux)))

(def (stop-http-server! httpd)
  (let (tgroup (thread-thread-group httpd))
    (try
     (!!httpd.shutdown httpd)
     (thread-join! httpd)
     (finally
      (thread-group-kill! tgroup)))))

;; handler: lambda (request response)
(def (http-register-handler httpd path handler (host #f))
  (if (string? path)
    (if (procedure? handler)
      (!!httpd.register httpd host path handler)
      (error "Bad handler; expected procedure" handler))
    (error "Bad path; expected string" path)))

;;; implementation
(def (http-server socks sas mux)
  (with-methods mux get-handler put-handler!)

  (def acceptors
    (parameterize ((current-http-server (current-thread)))
      (map
        (lambda (sock sa)
          (spawn/name 'http-server-accept
                      http-server-accept (cut get-handler mux <> <>) sock (socket-address-family sa)))
           socks sas)))

  (def (shutdown!)
    (for-each ssocket-close socks))

  (def (monitor thread)
    (def (join server thread)
      (with-catch void (cut thread-join! thread))
      (!!httpd.join server thread))
    (spawn/name 'http-server-monitor join (current-thread) thread))

  (def (loop)
    (<- ((!httpd.register host path handler k)
         (try
          (put-handler! mux host path handler)
          (!!value (void) k)
          (catch (e)
            (!!error e k)))
         (loop))
        ((!httpd.shutdown)
         (void))
        ((!httpd.join thread)
         (try
          (thread-join! thread)
          (warnf "acceptor thread ~a exited unexpectedly" (thread-name thread))
          (catch (uncaught-exception? e)
            (errorf "acceptor error: ~a" (uncaught-exception-reason e)))
          (catch (e)
            (errorf "acceptor error: ~a" e)))
         (loop))
        (bogus
         (warnf "unexpected message ~a" bogus)
         (loop))))

  (try
   (for-each monitor acceptors)
   (parameterize ((current-http-server (current-thread)))
     (loop))
   (catch (e)
     (errorf "unhandled exception: ~a" e)
     (raise e))
   (finally
    (shutdown!))))

(def (http-server-accept get-handler sock safamily)
  (def cliaddr (make-socket-address safamily))

  (def (loop)
    (let (clisock (ssocket-accept sock cliaddr))
       (spawn/name 'http-request-handler
                   http-request-handler get-handler clisock (socket-address->address cliaddr))
       (loop)))

  (let again ()
    (try
     (loop)
     (catch (os-exception? e)
       (errorf "error accepting connection: ~a" e)
       (again)))))
