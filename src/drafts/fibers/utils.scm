(define-module (drafts fibers utils)
 #:use-module (rnrs bytevectors)

 #:use-module (ice-9 textual-ports)

 #:export (make-default-socket run-server))

(define (make-default-socket family addr port)
  (let ((sock (socket PF_INET SOCK_STREAM 0)))
    (setsockopt sock SOL_SOCKET SO_REUSEADDR 1)
    (fcntl sock F_SETFD FD_CLOEXEC)
    (fcntl sock F_SETFL (logior O_NONBLOCK (fcntl sock F_GETFL)))
    (bind sock family addr port)
    sock))

(define* (run-server #:key
          (host #f)
          (family AF_INET)
          (addr INADDR_LOOPBACK)
          (port 11211)
          (socket (make-default-socket family addr port))
          socket-loop)
 (listen socket 1024)
 (sigaction SIGPIPE SIG_IGN)
 (socket-loop socket (make-hash-table)))
