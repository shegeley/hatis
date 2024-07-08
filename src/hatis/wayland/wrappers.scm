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

(define primary-event-handler
  (lambda (listener-class event-name args)
    (format #t "[~a] Event ~a/~a called with args ~a ~%"
            (timestamp)
            (class-name listener-class)
            (keyword->symbol event-name) args)))

(define (initialize-event events-hash-table primary-event-handler)
  (lambda (class event args)
    (let [(handler (hash-table-ref/default events-hash-table event #f))]
      (begin (primary-event-handler class event args)
             (if handler (handler class event args) #t)))))

(define (initialize-events-hash-table
          class events events-hash-table primary-event-handler)
  (map (lambda (event)
         (hash-table-set!
           events-hash-table event
           (initialize-event events-hash-table primary-event-handler)))
    events))

(define* (make-listener class
                        #:optional (args '())
                        #:key      (primary-event-handler primary-event-handler))
  "A simple wrapper around default guile-wayland's 'make' initializer to set all listener's handlers to default on on init no to set them all manually.

  @code{primary-event-handler} is a procedure of 3 arguments: listener-class (goops class), event-name (keyword), args (list of event arguments) it executes before supplied event handler (if any); if non handler supplied for the event, then only primary handler executes

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
  (let* [(keywordize-event  (lambda (x) (slot-definition-init-keyword x)))
         (normal-event?     (lambda (x) (not (equal? (keywordize-event x) #:%pointer))))
         (events            (filter-map (lambda (e) (if (normal-event? e) (keywordize-event e) #f))
                                        (class-slots class)))
         (events-hash-table (even-list->hash-table args))]
    (initialize-events-hash-table class events events-hash-table primary-event-handler)
    (apply make class (hash-table->even-list events-hash-table))))
