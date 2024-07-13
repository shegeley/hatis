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

  #:export (wrap-binder listener add-listener make-listener))

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

(define strip-goops-<>
 (compose ;; delete first + last character ("<"+">")
  (lambda (x) (string-drop x 1))
  (lambda (x) (string-drop-right x 1))))

(define get-stripped-class-name
 (compose strip-goops-<> symbol->string class-name))

(define (add-listener x listener)
  (let* [(class             (class-of x))
         (name              (get-stripped-class-name class))
         (procname          (string-append name "-add-listener"))
         (add-listener-proc (live-load procname))]
    (add-listener-proc x listener)))

(define (timestamp)
  (strftime "%c" (localtime (current-time))))

(define primary-handler
  (lambda (listener-class event-name args)
    (format #t "[~a] Event ~a/~a called with args ~a ~%"
            (timestamp)
            (class-name listener-class)
            (keyword->symbol event-name) args)))

(define (init-event class event primary-handler secondary-handler)
 (lambda wayland-event-args
  (begin
   (primary-handler class event wayland-event-args)
   (when secondary-handler
    (apply secondary-handler wayland-event-args)))))

(define (init-events-table class events events-hash-table primary-handler)
 (map (lambda (event)
       (hash-table-set! events-hash-table event
        (let [(secondary-handler (hash-table-ref/default events-hash-table event #f))]
         (init-event class event primary-handler secondary-handler)))) events))

(define* (make-listener class
          #:optional (args '())
          #:key      (primary-handler primary-handler))
 "A simple wrapper around default guile-wayland's 'make' initializer to set all listener's handlers to default on on init no to set them all manually.

  @code{primary-handler} is a procedure of 3 arguments: listener-class (goops class), event-name (keyword), args (list of event arguments) it executes before supplied event handler (if any); if non handler supplied for the event, then only primary handler executes

  @code{args} is an even-list of @code{event-name} @code{handler} where handler is a procedure or n-arity that accepts wayland listener's arguments.

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
        (event-acc         (lambda (e) (if (normal-event? e) (keywordize-event e) #f)))
        (events            (filter-map event-acc (class-slots class)))
        (events-hash-table (even-list->hash-table args))]
  (init-events-table class events events-hash-table primary-handler)
  (apply make class (hash-table->even-list events-hash-table))))

(define (listener x)
 "Return listener for x (dispatched by (class-of x)).
  @example
  (listener (make <wl-display>)) => #<<bytestructure-class> <wl-display-listener> 7f3da413ecf0>
  @end example "
 (let* [(name    (get-stripped-class-name (class-of x)))
        (varname (string-append "<" name "-listener" ">"))]
  (live-load varname)))
