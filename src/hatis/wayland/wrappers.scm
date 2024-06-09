(define-module (hatis wayland wrappers)
  #|
  This module exists because the way (guile-wayland) works is not very handy way of adding listeners + method.
  It autogenerates bindings + wrappers on the fly "dispatching" by object's class or else
  |#

  #:use-module (hatis utils)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-125)

  #:use-module ((wayland client protocol wayland)
                #:select (wl-registry-bind))

  #:use-module (clojureism)
  #:use-module (oop goops)

  #:export (wrap-binder add-listener make-listener))

(define* (wrap-binder ;; just duplicate #:global registry listener arguments
          data
          registry
          name
          interface
          version
          #:key ;; + additional key-arguments with defaults
          versioning)
  (let* [(interface- (_->- interface))
         (interface% (live-load (string-append "%" interface- "-interface")))
         (wrap-proc (live-load (string-append "wrap-" interface-)))
         (version (get versioning ;; default version is 1
                                  (string->symbol interface-)
                                  1))]
    (wrap-proc (wl-registry-bind registry name interface% version))))

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

(define (timestamp)
  (strftime "%c" (localtime (current-time))))

(define default-event-handler
  (lambda (listener-class event-name args)
    (format #t "[~a] Event ~a/~a called with args ~a ~%"
            (timestamp)
            (class-name listener-class)
            (keyword->symbol event-name) args)))

(define* (make-listener class
                        #:optional (args '())
                        #:key (event-handler default-event-handler))
  "A simple wrapper around default guile-wayland's 'make' initializer to set all listener's handlers to default on on init no to set them all manually.

  @code{event-handler} is a procedure of 3 arguments: listener-class (goops class), event-name (keyword), args (list of event arguments)

  @example
  (make <wl-touch-listener>
      #:up (lambda args (format #t \"up! ~a ~%\" args))
      #:motion (lambda args (format #t \"motion! ~a ~%\" args))
      #:down (lambda args (format #t \"down! ~a ~%\" args))
      ;; all the events must have handlers or it will cause an error
      ;; in wayland event loop
      ...)
  =>
  (make-listener <wl-touch-listener>)
  @end example"
  (let* [(events (filter-map
                  (lambda (x)
                    (let [(kw (slot-definition-init-keyword x))]
                      (if (not (equal? kw #:%pointer)) kw #f)))
                  (class-slots class)))
         (events-hash-table (alist->hash-table (even-list->alist args) eq?))
         (_  (map (lambda (e)
                    (cond
                     ((hash-table-exists? events-hash-table e) #f)
                     (else (hash-table-set!
                            events-hash-table e
                            (lambda args* (default-event-handler class e args*)))))) events))
         (args* (alist->even-list (hash-table->alist events-hash-table)))]
    (apply make class args*)))
