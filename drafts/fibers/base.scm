(define-module (drafts fibers base)
 #:use-module (rnrs bytevectors)

 #:use-module (ice-9 textual-ports)
 #:use-module (ice-9 rdelim)
 #:use-module (ice-9 match)

 #:use-module (fibers)
 #:use-module (fibers operations)
 #:use-module (fibers io-wakeup)
 #:use-module (fibers channels))

#| I'm not familiar with guile-fibers, so this is a draft module just to tryout it's concepts |#

#| Run with guile -s src/drafts/base.com |#

#| Interact via "socat":
<shegeley@prime:~/g-files>
zsh/2 4484  (git)-[master]-% echo "hello" | socat -t 30 tcp:localhost:11211 -
hello =)
|#

(define (make-default-socket family addr port)
  (let ((sock (socket PF_INET SOCK_STREAM 0)))
    (setsockopt sock SOL_SOCKET SO_REUSEADDR 1)
    (fcntl sock F_SETFD FD_CLOEXEC)
    (fcntl sock F_SETFL (logior O_NONBLOCK (fcntl sock F_GETFL)))
    (bind sock family addr port)
    sock))

(define (client-loop port addr store)
  (setvbuf port 'block 1024)
  ;; Disable Nagle's algorithm.  We buffer ourselves.
  (setsockopt port IPPROTO_TCP TCP_NODELAY 1)
  (let loop ()
    ;; TODO: Restrict read-line to 512 chars.
    (let ((line (read-line port)))
      (cond
       ((eof-object? line)
        (close-port port))
       (else
        (put-string port line)
        (put-string port " =)")
        (put-char port #\newline)
        (force-output port)
        (loop))))))

(define (socket-loop socket store)
  (let loop ()
    (match (accept socket SOCK_NONBLOCK)
      ((client . addr)
       (spawn-fiber (lambda () (client-loop client addr store)))
       (loop)))))

(define* (run-ping-server #:key
          (host #f)
          (family AF_INET)
          (addr (if host
                 (inet-pton family host)
                 INADDR_LOOPBACK))
          (port 11211)
          (socket (make-default-socket family addr port)))
 (listen socket 1024)
 (sigaction SIGPIPE SIG_IGN)
 (socket-loop socket (make-hash-table)))

(run-fibers run-ping-server)
