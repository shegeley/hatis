(define-module (hatis wayland seat)
  #:use-module (ice-9 match)
  #:use-module (ice-9 format)

  #:export (extract-capabilities))

(define (extract-capabilities x)
  ;; https://wayland.app/protocols/wayland#wl_seat:enum:capability
  (match x
    (7 '(pointer keyboard touch))
    (6 '(keyboard touch))
    (5 '(pointer touch))
    (4 '(touch))
    (3 '(keyboard pointer))
    (2 '(keyboard))
    (1 '(pointer))
    (else (error (format #f "Can't parse ~a ~%" x)))))
