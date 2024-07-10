(define-module (hatis wayland)
  #:use-module (wayland client display)
  #:use-module (wayland client protocol input-method)
  #:use-module (wayland client protocol wayland)
  #:use-module (wayland client protocol xdg-shell)
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

  #:use-module (clojureism associative)
  #:use-module (clojureism atomic)

  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (ice-9 threads)
  #:use-module (ice-9 atomic)

  #:use-module (oop goops))

(define (current-desktop)
  (getenv "XDG_CURRENT_DESKTOP"))

(define events-channel (make-channel))

(define state
  #| State is an atom hash-map of following structure:
  - active-interfaces - hash-map of (class-of interface) and an interface
  - keymap - current keymap
  |#
  ;; Using `'eq?`' is critical for comparing guile-bytestructures (see README.org notes)
  (let [(active-interfaces (make-hash-table eq?))]
    (make-atomic-box
     (alist->hash-table
      `((active-interfaces . ,active-interfaces)
        (keymap . #f)) eq?))))

(define (get-interface x)
  (get-in (ref state) `(active-interfaces ,x)))

(define i get-interface) ;; shorten

(define (activate-interface! x)
  (swap! state (lambda (s) (assoc-in s `(active-interfaces ,(class-of x)) x))))

(define (deactivate-interface! x)
  (swap! state (lambda (s) (assoc-in s `(active-interfaces ,(class-of x)) #f))))

(define (catch-keymap keymap)
  (swap! state (lambda (s) (assoc-in s '(keymap) keymap))))

(define (releasers)
  (alist->hash-table
    `((,<zwp-input-method-manager-v2> . ,zwp-input-method-manager-v2-destroy)
      (,<zwp-input-method-v2> . ,zwp-input-method-v2-destroy))
    eq?))

(define* (release-interface x #:key (releasers releasers))
  (let [(releaser (get (releasers) (class-of x)))]
    (when releaser (releaser x))
    (deactivate-interface! x)))

(define (sway:wrap-binder . args)
  (apply wrap-binder (append args (list #:versioning sway:versioning))))

(define channel-event-handler
  (lambda (listener-class event-name args)
    (put-message events-channel
      (list listener-class event-name args))))

(define* (make-listener* class #:optional (args '()))
  (make-listener class args #:primary-handler channel-event-handler))

(define touch-listener   (make-listener* <wl-touch-listener>))
(define pointer-listener (make-listener* <wl-pointer-listener>))
(define seat-listener    (make-listener* <wl-seat-listener>))

(define registry:required-interfaces
 '("wl_compositor"
   "wl_seat"
   "zwp_input_method_manager_v2"
   "xdg_wm_base"))

(define (registry:global-handler . args)
  (match-let* [((data registry name interface version) args)]
    (when (member interface registry:required-interfaces)
      (catch-interface (apply sway:wrap-binder args)))))

(define registry-listener
  (make-listener* <wl-registry-listener>
    (list #:global registry:global-handler)))

(define keyboard-grab-listener
  (make-listener* <zwp-input-method-keyboard-grab-v2-listener>
    (list #:keymap
      (lambda args
        (catch-keymap (apply get-keymap (drop args 2)))))))

(define (catch-input-surface) ;; broken
  (catch-interface (wl-compositor-create-surface (i <wl-compositor>)))
  (catch-interface (zwp-input-method-v2-get-input-popup-surface
                    (i <zwp-input-method-v2>) ;; throws "invalid argument" on this argument
                    (i <wl-surface>))))

(define input-method-listener
  (make-listener* <zwp-input-method-v2-listener>
    (list #:activate
      (lambda (_ im)
        ;; (catch-input-surface) ;; TODO: fix
        (catch-interface (zwp-input-method-v2-grab-keyboard im)))
      #| #:deactivate
      (lambda args
        #| Release keyboard NEEDED? |#
      (zwp-input-method-keyboard-grab-v2-release (keyboard))) |#)))

(define (listeners)
  "Here listeners is a proc because guile don't have clojure-alike `declare' and listeners are declared after their reference"
  (alist->hash-table
    `((,<wl-seat> . ,seat-listener)
       (,<wl-touch> . ,touch-listener)
       (,<wl-registry> . ,registry-listener)
       (,<wl-pointer> . ,pointer-listener)
       (,<zwp-input-method-keyboard-grab-v2> . ,keyboard-grab-listener)
       (,<zwp-input-method-v2> . ,input-method-listener)) eq?))

(define* (add-listener* x #:key (listeners listeners))
  ;; NOTE: ares will fail to eval if (listeners) are not dynamic call
  (let [(listener (get (listeners) (class-of x)))]
    (when listener (add-listener x listener)) #t))

(define* (catch-interface x #:key (listeners listeners))
  (cond
    ;; interface already active
    ((i (class-of x)) (release-interface x))
    ;; x if false := failed to get it (for example devices won't have touch capability)
    ((equal? #f x) #f)
    (else (activate-interface! x)
          (add-listener* x #:listeners listeners))))

(define (setup) (gc-disable))

(define (connect)
  (catch-interface (wl-display-connect))

  (unless (i <wl-display>)
    (error (format (current-error-port) "Unable to connect to wayland compositor~%"))))

(define (get-registry)
  (catch-interface (wl-display-get-registry (i <wl-display>))))

(define (roundtrip)
  (wl-display-roundtrip (i <wl-display>)))

(define (get-input-method)
  (unless (i <zwp-input-method-manager-v2>)
    (error (format #f "Can't access input-manager!")))

  (catch-interface
   (zwp-input-method-manager-v2-get-input-method
    (i <zwp-input-method-manager-v2>)
    (i <wl-seat>))))

(define (spin)
 (while #t (roundtrip)))

(define (start)
  ;; (setup)
  (connect)
  (get-registry)
  ;; roundtip here is needed to catch* all the interfaces inside registry-listener
  ;; https://wayland.freedesktop.org/docs/html/apb.html#Client-classwl__display_1ab60f38c2f80980ac84f347e932793390
  (roundtrip)
  (get-input-method)
  (spin))

(define thread (call-with-new-thread start))

(define (stop)
 (when (and (not (thread-exited? thread))
            (i <wl-registry>))
  (cancel-thread thread)
  (wl-display-flush (i <wl-display>))
  (wl-display-disconnect (i <wl-display>))))

(define (insert text)
  (when (string? text)
    (zwp-input-method-v2-commit-string (i <zwp-input-method-v2>) text)
    (zwp-input-method-v2-commit (i  <zwp-input-method-v2>) 1)))

(use-modules (ice-9 suspendable-ports))
(install-suspendable-ports!)

(define (log port message)
  (wait-until-port-writable-operation port)
  (format port "~a ~%" message))

(define* (handling-loop #:key port)
 (let loop []
  (let* [(message (get-message events-channel))]
   (log port message)
   (loop))))

(define handling-thread
 (call-with-new-thread
   (lambda ()
     (call-with-output-file "./output.txt"
       (lambda (port) (handling-loop #:port port))))))

;; (cancel-thread handling-thread)
;; (stop)
;; (insert "sas")
;; (zwp-input-method-v2-commit-string (i <zwp-input-method-v2>) "kek")
