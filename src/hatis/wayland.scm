(define-module (hatis wayland)
  #:use-module (wayland client display)
  #:use-module (wayland client protocol input-method)
  #:use-module (wayland client protocol wayland)
  #:use-module (wayland interface)
  #:use-module (wayland client proxy)

  #:use-module ((hatis sway) #:prefix sway:)
  #:use-module (hatis wayland seat)
  #:use-module (hatis wayland keyboard)
  #:use-module (hatis wayland wrappers)
  #:use-module (hatis utils)

  #:use-module (fibers)
  #:use-module (fibers channels)
  #:use-module (fibers operations)
  #:use-module (fibers io-wakeup)

  #:use-module ((srfi srfi-1) #:hide (assoc)) ;; list base
  #:use-module (srfi srfi-125) ;; hash-tables

  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (ice-9 threads)
  #:use-module (ice-9 atomic)

  #:use-module (oop goops))

(define wayland-events-channel (make-channel))

(define %display  #f)
(define %registry #f)

(define (sway:wrap-binder . args)
  (apply wrap-binder (append args (list #:versioning sway:versioning))))

(define channel-event-handler
 (lambda args ;; (event-listener-class event-name event-args)
  (put-message wayland-events-channel args)))

(define* (make-listener* class #:optional (args '()))
  (make-listener class args #:primary-handler channel-event-handler))

(define (add-listener* wayland-interface)
 (add-listener wayland-interface
  (make-listener* (listener wayland-interface))))

(define (try-add-listener* wayland-interface)
 (false-if-exception (add-listener* wayland-interface)))

(define (handle-interface wayland-interface)
 (try-add-listener* wayland-interface))

(define (registry:global-handler . args)
 (let* [(interface (false-if-exception (apply sway:wrap-binder args)))]
  (when interface (handle-interface interface))))

(define registry-listener
  (make-listener* <wl-registry-listener>
    (list #:global registry:global-handler)))

(define (connect)
  (set! %display (wl-display-connect))
 (unless %display
    (error (format (current-error-port) "Unable to connect to wayland compositor~%"))))

(define (get-registry)
 (begin
  (set! %registry (wl-display-get-registry %display))
  (add-listener %registry registry-listener)))

(define (roundtrip) (wl-display-roundtrip %display))

(define (spin) (while #t (roundtrip)))

(define (start!)
  (connect)
  (get-registry)
  ;; roundtip here is needed to catch* all the interfaces inside registry-listener
  ;; https://wayland.freedesktop.org/docs/html/apb.html#Client-classwl__display_1ab60f38c2f80980ac84f347e932793390
  (roundtrip)
  ;; (get-input-method)
  (spin))

(define thread #f)

(define (run!)
 (set! thread (call-with-new-thread start!)))

(define (exit!)
 (when (not (thread-exited? thread))
  (cancel-thread         thread)
  (wl-display-flush      %display)
  (wl-display-disconnect %display)))

;; (run!)

;; (get-message wayland-events-channel)
