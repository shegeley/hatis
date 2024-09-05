(define-module (hatis wayland)
  #:use-module (wayland client display)
  #:use-module (wayland client protocol wayland)
  #:use-module (wayland interface)
  #:use-module (wayland client proxy)

  #:use-module (wayland client protocol input-method)

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

;; (define wayland-events-channel (make-channel))

(define %display         #f)
(define %registry        #f)
(define %log            '())
(define %raw-interfaces '())
(define %interfaces     '())

;; log
(define* (get-events #:optional (interface #f))
  (filter (lambda (e)
            (if interface
                (eq? (listener interface) (first e))
                #t)) %log))

(define channel-event-handler
 (lambda args ;; (event-listener-class event-name event-args)
  ;; (put-message wayland-events-channel args)
  (set! %log (cons args %log))
  #t))

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
 (try-add-listener* wayland-interface)
 (catch-interface! wayland-interface))

;; %interfaces
(define (get-interface class)
  (find (lambda (x) (eq? (class-of x) class)) %interfaces))

(define i get-interface)

(define (catch-interface! interface)
  (set! %interfaces (cons interface %interfaces)))

;; registry

(define (registry:try-init-interface data registry name interface version)
  "Not all interfaces can init. Only those which was loaded with (use-wayland-protocol ...) in their module and required in the current module"
  (set! %raw-interfaces (cons (list data registry name interface version)
                             %raw-interfaces))
  (false-if-exception (registry:init-interface data registry name interface version)))

(define (registry:global-handler data registry name interface version)
 "registry's #:global handler"
 (let* [(interface (registry:try-init-interface data registry name interface version))]
  (when interface (handle-interface interface))))

(define registry-listener
  (make-listener* <wl-registry-listener>
    (list #:global registry:global-handler)))

;; main event loop
(define (connect)
 (set! %display (wl-display-connect))
 (unless %display
  (error (format (current-error-port) "Unable to connect to wayland compositor~%"))))

(define (roundtrip) (wl-display-roundtrip %display))
(define (sync)      (wl-display-sync %display))
(define (dispatch)  (wl-display-dispatch %display))
(define (spin)      (while #t (dispatch)))

(define (get-registry)
  (set! %registry (wl-display-get-registry %display))
  (sync)
  (add-listener %registry registry-listener)
  (roundtrip))

(define (start!)
  (connect)
  (get-registry)
  ;; (get-input-method)
  (spin))

;; control flow

(define thread #f)

(define (run!)
  (if thread
      (restart!)
      (set! thread (call-with-new-thread start!))))

(define (exit!)
 (when (and thread (not (thread-exited? thread)))
  (cancel-thread         thread)
  (set!         thread   #f)
  (set!    %interfaces   '())
  (set!           %log   '())
  (wl-display-flush      %display)
  (wl-display-disconnect %display)))

(define (restart!) (exit!) (run!))

;; (run!)

;; (get-events)

;; %raw-interfaces

;; %interfaces

;; (roundtrip)

;; (use-modules (system vm trace))

;; (roundtrip)

#| ;; STASH
(define (get-input-method)
(unless (i <zwp-input-method-manager-v2>)
(error (format #f "Can't access input-manager!")))


(handle-interface
(zwp-input-method-manager-v2-get-input-method
(i <zwp-input-method-manager-v2>)
(i <wl-seat>))))

(define (get-keyboard)
(let* [(seat     (i <wl-seat>))
(keyboard (wl-seat-get-keyboard seat))]
(handle-interface keyboard)))
|#
