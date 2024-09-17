(define-module (drafts fibers swaymsg)
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

 #:use-module (drafts fibers utils)

 #:use-module (hatis swaymsg))

#|
original idea:
> scan current focused window pid/app-id/title in an endless loop; dispatch based on it's value: if the title :=  "firefox" enter a string and display it back;
updates:
  - how do I enter a string if the focus is on firefox? either need to show some GUI overlay with input-field on it on top of the current toplevel or just "simulate" some kind of nororious operation when the context is on firefox
  - say launching another gui application and kill it if the focus is moved
|#

(define C (make-channel))

(define pid* #f)

(define (get-toplevel-loop channel)
 (let loop () (put-message channel (get-toplevel 'app-id)) (loop)))

(define (handle)
 (let loop [(val (get-message C))]
  (cond
   ((equal? val "\"org.gnome.clocks\"")
    (let [(pid (get-toplevel 'pid))]
     (pk pid)
     (set! pid* (string->number pid))
     (pk 'pid1 pid*)))
   ((number? pid*) (pk 'killing pid*) (kill pid* SIGKILL))
   (else #f))
  (loop (get-message C))))

(define (client-loop port addr store)
 (setvbuf port 'block 1024)
 (setsockopt port IPPROTO_TCP TCP_NODELAY 1)
 (let loop [(old-val #f)
            (new-val (get-message C))]
  (cond
   ((not (equal? new-val old-val))
    (put-string port new-val) (put-char port #\newline)
    (force-output port))
   (else #f))
  (loop new-val (get-message C))))

(define (socket-loop socket store)
 (let loop ()
  (match
   (accept socket SOCK_NONBLOCK)
   ((client . addr)
    (spawn-fiber (lambda () (client-loop client addr store)))
    (spawn-fiber (lambda () (get-toplevel-loop C)))
    (spawn-fiber handle)
    (loop)))))

(run-fibers (lambda () (run-server #:socket-loop socket-loop)))
