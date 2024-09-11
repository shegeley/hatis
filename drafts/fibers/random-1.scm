(define-module (drafts fibers random-1)
 #:use-module (rnrs bytevectors)

 #:use-module (ice-9 textual-ports)
 #:use-module (ice-9 threads)
 #:use-module (ice-9 rdelim)
 #:use-module (ice-9 match)

 #:use-module (fibers)
 #:use-module (fibers conditions)
 #:use-module (fibers operations)
 #:use-module (fibers io-wakeup)
 #:use-module (fibers channels))

#|
  in server-loop: read number from /dev/random (or just generate with (random)) and send to channel
  in client-loop: if the number is not even - then just display this number and show =) at the end AND loop again (get another number), otherwise ask some user input and display it with =) at the end and quit
|#

(define (make-default-socket family addr port)
 (let ((sock (socket PF_INET SOCK_STREAM 0)))
  (setsockopt sock SOL_SOCKET SO_REUSEADDR 1)
  (fcntl sock F_SETFD FD_CLOEXEC)
  (fcntl sock F_SETFL (logior O_NONBLOCK (fcntl sock F_GETFL)))
  (bind sock family addr port)
  sock))

(define C (make-channel))

(define (handle-even x port addr _)
 (put-string port " =)")
 (put-char port #\newline)
 (force-output port))

(define (handle-odd x port addr _)
 (put-string port "please enter something: ")
 (force-output port)
 (let ((line (read-line port)))
  (cond
   ((eof-object? line) (close-port port))
   (else
    (put-string port line)
    (put-string port " =)")
    (put-char port #\newline)
    (force-output port)))))

(define (client-loop port addr store)
 (setvbuf port 'block 1024)
 (setsockopt port IPPROTO_TCP TCP_NODELAY 1)
 (let loop ()
  (let* [(x (get-message C))
         (y (modulo x 2))]
   (pk 'x x 'y y)
   (put-string port (number->string x))
   (put-char port #\newline)
   (force-output port)
   (cond
    ((eq? y 0)
     (handle-even x port addr store)
     (shutdown port 2))
    (else
     (handle-odd x port addr store)
     (loop))))))

(define (random-number-generator channel)
 (let loop [(n (random 10))]
  (pk 'n n)
  (put-message channel n)
  (loop (random 10))))

(define (socket-loop socket store)
 (let loop ()
  (match
   (accept socket SOCK_NONBLOCK)
   ((client . addr)
    (spawn-fiber (lambda () (random-number-generator C)))
    (spawn-fiber (lambda () (client-loop client addr store)))
    (loop)))))


(define* (run-ping-server #:key
          (host   #f)
          (family AF_INET)
          (addr   INADDR_LOOPBACK)
          (port   11211)
          (socket (make-default-socket family addr port)))
 (listen socket 1024)
 (sigaction SIGPIPE SIG_IGN)
 (socket-loop socket (make-hash-table)))

(run-fibers run-ping-server)
