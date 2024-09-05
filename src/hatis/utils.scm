(define-module (hatis utils)
  #:use-module (rnrs bytevectors)

  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (ice-9 string-fun)
  #:use-module (ice-9 binary-ports)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-125)

  #:export (read-string-from-fd
            _->- -->_ live-load
            even-list->alist
            alist->even-list
            hash-table->even-list
            even-list->hash-table))

(define (read-string-from-fd fd)
  (call-with-port (fdopen fd "rb")
    (compose utf8->string get-bytevector-all)))

(define (_->- str) (string-replace-substring str "_" "-"))

(define (-->_ str) (string-replace-substring str "-" "_"))

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

(define (hash-table->even-list hash-table)
  (alist->even-list (hash-table->alist hash-table)))

(define* (even-list->hash-table even-list #:optional (comparator eq?))
  (alist->hash-table (even-list->alist even-list) comparator))
