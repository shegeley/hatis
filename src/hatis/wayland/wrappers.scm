(define-module (hatis wayland wrappers)
  #|
  This module exists because the way (guile-wayland) works is not very handy way of adding listeners + method.
  It autogenerates bindings + wrappers on the fly "dispatching" by object's class or else
  |#

  #:use-module ((hatis utils)
                #:select (live-load _->-))

  #:use-module (oop goops)

  #:use-module (srfi srfi-69) ;; hash-tables

  #:export (wrap-binder
            add-listener))

(define* (wrap-binder ;; just duplicate #:global registry listener arguments
          data
          registry
          name
          interface
          version
          #:key ;; + additional key-arguments with defaults
          versioning)
  (let* [(interface- (_->- interface))
         (wrap-proc (live-load (string-append "wrap-" interface-)))
         (bind-proc (live-load (string-append "%" interface- "-interface")))]
    (wrap-proc (bind-proc (hash-table-ref versioning (string->symbol interface-))))))

(define (add-listener x listener)
  (let* [(class (class-of x))
         (get-name (compose
                    string->symbol
                    (compose ;; delete first + last character ("<"+">")
                     (lambda (x) (string-drop x 1))
                     (lambda (x) (string-drop-right x 1)))
                    symbol->string
                    class-name))
         (name (get-name class))
         (add-listener-proc (live-load (symbol-append name '-add-listener)))]
    (add-listener-proc x listener)))
