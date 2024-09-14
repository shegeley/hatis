(define-module (drafts fibers random)
 #:use-module (rnrs bytevectors)

 #:use-module (ice-9 textual-ports)
 #:use-module (ice-9 threads)
 #:use-module (ice-9 rdelim)
 #:use-module (ice-9 match)

 #:use-module (fibers)
 #:use-module (fibers conditions)
 #:use-module (fibers operations)
 #:use-module (fibers io-wakeup)
 #:use-module (fibers channels)

 #:use-module (drafts fibers utils))

#|
  in server-loop: read number from /dev/random (or just generate with (random)) and send to channel
  in client-loop: just display this number and show =) at the end
|#

#|
<shegeley@prime:~/g-files>
zsh/2 4668  (git)-[master]-% socat tcp-connect:localhost:11211  -
5 =)
---
  ↑ exits immidiately after the output; if line [1] is removed, than the connection hangs
|#

(define C (make-channel))

(define (client-loop port addr store)
 (setvbuf port 'block 1024)
 (setsockopt port IPPROTO_TCP TCP_NODELAY 1)
 (put-string port (number->string (get-message C)))
 (put-string port " =)")
 (put-char port #\newline)
 (force-output port)
 (shutdown port 2) #| [1] |#)

(define (socket-loop socket store)
 (let loop ()
  (match
   (accept socket SOCK_NONBLOCK)
   ((client . addr)
    (spawn-fiber (lambda () (put-message C (random 10))))
    (spawn-fiber (lambda () (client-loop client addr store)))
    (loop)))))

(define thread
 (run-fibers (lambda () (run-server #:socket-loop socket-loop))))
