(define-module (packages sway)
 #:use-module (guix packages)
 #:use-module (packages wlroots)
 #:use-module (gnu packages wm))

(define ->bleeding-edge*
 (compose
  ->bleeding-edge
  (package-input-rewriting
   `((,wlroots . ,wlroots/latest)))))

(define-public sway/latest
 (->bleeding-edge*
  (package
   (inherit sway)
   (version "1.9"))))

sway/latest
