(define-module (hatis wayland)
  #:use-module (wayland client display)
  #:use-module (wayland client protocol input-method)
  #:use-module (wayland client protocol wayland)
  #:use-module (wayland interface)
  #:use-module (wayland client proxy)

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

(define channel-event-handler
 (lambda args ;; (event-listener-class event-name event-args)
  (put-message wayland-events-channel args)))

(define* (make-listener* class #:optional (args '()))
  (make-listener class args #:primary-handler channel-event-handler))

(define (add-listener* wayland-interface)
 (add-listener wayland-interface
  (make-listener* (listener wayland-interface))))

(define (try-add-listener* wayland-interface)
 "Not all interfaces might emit events.
  wl_compositor, wl_subcompositor, wl_shm_pool, wl_region, wl_subsurface"
 (false-if-exception (add-listener* wayland-interface)))

(define (handle-interface wayland-interface)
 (try-add-listener* wayland-interface))

(define (registry:try-init-interface data registry name interface version)
 "Not all interfaces can init. Only those which was loaded with (use-wayland-protocol ...) in their module and required in the current module"
 (false-if-exception (registry:init-interface data registry name interface version)))

(define (registry:global-handler data registry name interface version)
 "registry's #:global handler"
 (let* [(interface (registry:try-init-interface data registry name interface version))]
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
  ;; https://wayland.app/protocols/wayland#wl_registry
  ;; «To mark the end of the initial burst of events, the client can use the wl_display.sync request immediately after calling wl_display.get_registry»
  (wl-display-sync %display)
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

(define (get-message* channel)
 "A workaround to get-message from empty channel and not break the memort (error 139 sigsegv)
  Won't remove message from the channel if it's the last one (will always return it)"
 (with-continuation-barrier (lambda () (get-message channel))))

;; (run!)

;; (exit!)

;; (get-message* wayland-events-channel)
