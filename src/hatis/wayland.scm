(define-module (hatis wayland)
  #:use-module (wayland proxy)
  #:use-module (wayland interface)
  #:use-module (wayland client display)
  #:use-module (wayland client protocol input-method)
  #:use-module (wayland client protocol wayland)
  #:use-module (wayland client protocol xdg-shell)

  #:use-module ((hatis sway) #:prefix sway:)
  #:use-module (hatis wayland seat)
  #:use-module (hatis wayland keyboard)
  #:use-module (hatis wayland wrappers)

  #:use-module (fibers)
  #:use-module (fibers channels)

  #:use-module (srfi srfi-1) ;; list base
  #:use-module (srfi srfi-69) ;; hash-tables

  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (ice-9 threads)
  #:use-module (ice-9 atomic)

  #:use-module (oop goops))

;; clojure-alike atomic-box interfaces
(define (reset! cage val)
  (atomic-box-set! cage val))

(define (ref cage)
  (atomic-box-ref cage))

(define (update cage f)
  (reset! cage (f (ref cage))))
;; end

(define (current-desktop)
  (getenv "XDG_CURRENT_DESKTOP"))

(define chan
  (make-channel))

(define compositor
  (make-atomic-box #f))

(define display
  (make-atomic-box #f))

(define registry
  (make-atomic-box #f))

(define seat
  (make-atomic-box #f))

(define pointer
  (make-atomic-box #f))

(define touch
  (make-atomic-box #f))

(define input-method-manager
  (make-atomic-box #f))

(define input-method
  (make-atomic-box #f))

(define input-surface
  ;; https://wayland.app/protocols/input-method-unstable-v2#zwp_input_popup_surface_v2
  (make-atomic-box #f))

(define xdg-input-surface
  ;; https://wayland.app/protocols/xdg-shell#xdg_surface
  (make-atomic-box #f))

(define keyboard
  (make-atomic-box #f))

(define keymap
  (make-atomic-box #f))

(define xdg-wm-base
  ;; The xdg_wm_base interface is exposed as a global object enabling clients to turn their wl_surfaces into windows in a desktop environment. It defines the basic functionality needed for clients and the compositor to create windows that can be dragged, resized, maximized, etc, as well as creating transient windows such as popup menus.
(make-atomic-box #f))

(define (releasers)
  (alist->hash-table
   `((,<zwp-input-method-manager-v2> . ,zwp-input-method-manager-v2-destroy)
     (,<zwp-input-method-v2> . ,zwp-input-method-v2-destroy))))

(define* (release cage x #:key (releasers releasers))
  (let [(release (hash-table-ref (releasers) (class-of x) (const #f)))]
    (when release (release x))
    (reset! cage #f)))

(define (sway:wrap-binder . args)
  (apply wrap-binder (append args (list #:versioning sway:versioning))))

(define touch-listener
  (make-listener <wl-touch-listener>))

(define pointer-listener
  (make-listener <wl-pointer-listener>))

(define seat-listener
  (make-listener <wl-seat-listener>
                 (list #:name (lambda args (format #t "seat:name ~a ~%" args))
                       #:capabilities (lambda (_1 _2 x)
                                        (let [(capabilities (extract-capabilities x))]
                                          ;; not sure if i need to do something with pointer/touch/keyboard now
                                          ;; or only when keyboard is catched
                                          (cond ((member 'keyboard capabilities)
                                                 (format #t "Do something with keyboard ~%"))
                                                ((member 'touch capabilities)
                                                 (format #t "Do something with touch ~%"))
                                                ((member 'pointer capabilities)
                                                 (format #t "Do something with pointer %~"))))))))

(define registry-listener
  (make-listener <wl-registry-listener>
    (list #:global
          (lambda* args
            (match-let* [((data registry name interface version) args)]
              (format #t "interface: '~a', version: ~a, name: ~a ~%"
                      interface version name)
              (when (member interface '("wl_compositor" "wl_seat" "zwp_input_method_manager_v2" "xdg_wm_base"))
                (let [(wrapped (apply sway:wrap-binder args))]
                  (cond
                   ((string=? "wl_compositor" interface)
                    (catch* compositor wrapped))
                   ((string=? "wl_seat" interface)
                    (catch* seat wrapped))
                   ((string=? "zwp_input_method_manager_v2" interface)
                    (catch* input-method-manager wrapped))
                   ((string=? "xdg_wm_base" interface)
                    (catch* xdg-wm-base wrapped)))))))
          #:global-remove
          (lambda (data registry name)
            (pk 'remove data registry name)))))

(define (handle-key-press . args)
  "let if be as is for now. but I guess enhanced interception logic needed.
   like:
    (define (wrap-handle-press-event pointer grab serial timestamp key state)
        (alist->hash-table `((serial . ,serial)
                            (timestamp . ,timestamp)
                            (key . ,key)
                            (state . ,state))))"
  (format #t "key! args: ~a ~%" args)
  ;; (put-message chan (list #:key args))
  )

(define keyboard-grab-listener
  (make-listener <zwp-input-method-keyboard-grab-v2-listener>
                 (list #:keymap
                       (lambda args
                         (format #t "keymap! args: ~a ~%" args)
                         (catch* keymap (apply get-keymap (drop args 2))))
                       #:key handle-key-press)))

(define input-method-listener
  (make-listener <zwp-input-method-v2-listener>
                 (list #:activate
                       (lambda (_ im)
                         (format #t "activate! im: ~a ~%" im)
                         ;; NOTE: need to grab keyboard + input surface

                         ;; Catch* surface
                         (catch* input-surface (wl-compositor-create-surface (ref compositor)))

                         ;; popup-input-surface won't cast to xdg-surface
                         ;; (xdg-input-surface (xdg-wm-base-get-xdg-surface (xdg-wm-base) (input-surface)))
                         ;; ERROR: «not a <wl-surface> or #f #<<zwp-input-popup-surface-v2> 7efd12918c80>»

                         (catch* input-surface (zwp-input-method-v2-get-input-popup-surface im (ref input-surface)))

                         ;; Grab keyboard
                         (catch* keyboard (zwp-input-method-v2-grab-keyboard im)))
                       #:deactivate
                       (lambda args
                         ;; Release keyboard NEEDED?
                         ;; (zwp-input-method-keyboard-grab-v2-release (keyboard))
                         (format #t "leave! args: ~a ~%" args)))))

(define (listeners)
  "Here listeners is a proc because guile don't have clojure-alike `declare' and listeners are declared after their reference"
  (alist->hash-table
   `((,<wl-seat> . ,seat-listener)
     (,<wl-touch> . ,touch-listener)
     (,<wl-registry> . ,registry-listener)
     (,<wl-pointer> . ,pointer-listener)
     (,<zwp-input-method-keyboard-grab-v2> . ,keyboard-grab-listener)
     (,<zwp-input-method-v2> . ,input-method-listener))))

(define* (catch* cage x #:key (listeners listeners))
  (format #t "Catch* ~a into ~a ~%" x cage)
  (cond
   ;; cage is occupied already
   ((ref cage)
    (release cage x))
    ;; x if false := failed to get it (for example devices won't have touch capability)
   ((equal? #f x) #f)
   ;; else
   (else
    (begin
      (reset! cage x)
      (let [(listener (hash-table-ref
                       (listeners) ;; ares will fail to eval if this one is not dynamic call
                       (class-of x)
                       (const #f)))]
        (when listener (add-listener x listener))
        #t)))))

(define (main)
  (catch* display (wl-display-connect))
  (unless (ref display)
    (display "Unable to connect to wayland compositor")
    (newline)
    (exit -1))

  (catch* registry (wl-display-get-registry (ref display)))

  ;; roundtip here is needed to catch* all the interfaces inside registry-listener
  ;; https://wayland.freedesktop.org/docs/html/apb.html#Client-classwl__display_1ab60f38c2f80980ac84f347e932793390
  (wl-display-roundtrip (ref display))

  (if (ref input-method-manager)
      (format #t "Input manager available: ~a ~%" (ref input-method-manager))
      (error (format #f "Can't access input-manager!")))

  (catch* input-method
    (zwp-input-method-manager-v2-get-input-method
     (ref input-method-manager)
     (ref seat)))

  (format #t "Input-method: ~a ~%" (ref input-method))

  (while #t (wl-display-roundtrip (ref display))))

(define output-file
  (make-parameter "./output.txt"))

(define (reset-output)
  (when (file-exists? (output-file))
    (delete-file (output-file))))

(define output-port
  (open-file (output-file) "a0"))

(define thread
  (call-with-new-thread
   (lambda ()
     (with-output-to-port output-port main))))

#|
(zwp-input-method-v2-commit-string (ref input-method) "Lorem ipsum")
(zwp-input-method-v2-commit (ref input-method) 1)
|#
