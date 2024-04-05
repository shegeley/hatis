(define-module (hatis utils)
  #:use-module (rnrs bytevectors)

  #:use-module (ice-9 string-fun)
  #:use-module (ice-9 binary-ports)

  #:export (read-string-from-fd _->- live-load))

(define (read-string-from-fd fd)
  (call-with-port (fdopen fd "rb")
    (compose utf8->string get-bytevector-all)))

(define (_->- str)
   (string-replace-substring str "_" "-"))

(define* (live-load x #:key (module (current-module)))
  (module-ref
   module
   (cond ((string? x) (string->symbol x))
         ((symbol? x) x))))
