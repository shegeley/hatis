(define-module (hatis utils)
  #:use-module (rnrs bytevectors)

  #:export (read-string-from-fd))

(define (read-string-from-fd fd)
  (call-with-port (fdopen fd "rb")
    (compose utf8->string get-bytevector-all)))
