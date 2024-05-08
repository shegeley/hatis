(define-module (hatis utils)
  #:use-module (rnrs bytevectors)

  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (ice-9 string-fun)
  #:use-module (ice-9 binary-ports)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-69) ;; hash-tables

  #:export (read-string-from-fd
            _->- live-load
            even-list->alist
            alist->even-list
            reset! ref update))

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

(define (even-list->alist list)
  (match list
    ('() '())
    ((a) (error (format #f "~a is not an even list! ~%" list)))
    ((a b) `((,a . ,b)))
    ((a b c ...) (alist-cons a b (even-list->alist c)))))

(define alist->even-list
  (match-lambda
    ('() '())
    (((a . b) rest ...) (append (list a b) (alist->even-list rest)))))

;; BEGIN: clojure-alike atomic-box & hash-map interfaces

(define (reset! cage val)
  (atomic-box-set! cage val))

(define (ref cage)
  (atomic-box-ref cage))

(define (update cage f)
  (reset! cage (f (ref cage))))

;; END
