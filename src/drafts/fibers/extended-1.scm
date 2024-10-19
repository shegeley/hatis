(define-module (drafts fibers extended-1)
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
[original idea] 3 endless loops:
1. Just print ":)" in current-output-port every second
2. Reads battery level (/sys/class/power_supply/BAT0/capacity) and sends it to Channel-1
3. Takes messaged from Channel-1 and prints it in current-output-port every second

When 1 loop is printed 5 times block the 3rd loops via make-condition. So that messages of battry level would just stack in a Channel-1.
|#

(define battery-capacity-location "/sys/class/power_supply/BAT0/capacity")

(define channel:battery-capacity (make-channel))

(define (fiber:hello)
 (let loop [(i 0)]
  (display "=)")
  (wait 1)
  (loop (+ 1 i))))

(define (get-battery-capacity)
 (call-with-input-file battery-capacity-location get-string-all))

(define (fiber:get-battery-capacity)
 (let loop [(current-capacity (get-battery-capacity))]
  (display current-capacity)
  (waiy 1)
  (loop (get-battery-capacity))))

(define (fiber:display-battery-capacity)
 (let loop [(msg '())]
  (unless (eq? msg '())
   (display msg)
   (wait 1))
  (loop (msg (get-message channel:battery-capacity)))))

(define (start)
 (run-fibers (lambda () (spawn-fiber ()))))
