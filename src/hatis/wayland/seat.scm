(define-module (hatis wayland seat)
  #:use-module (srfi srfi-125)

  #:export (extract-capabilities))

(define capabilities-table
  (alist->hash-table
   `((7 . (pointer keyboard touch))
     (6 . (keyboard touch))
     (5 . (pointer touch))
     (4 . (touch))
     (3 . (keyboard pointer))
     (2 . (keyboard))
     (1 . (pointer))) eqv?))

(define (extract-capabilities value)
  "https://wayland.app/protocols/wayland#wl_seat:enum:capability"
  (hash-table-ref/default capabilities-table value #f))
