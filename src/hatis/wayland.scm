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

  #:use-module (srfi srfi-1) ;; list base
  #:use-module (srfi srfi-125) ;; hash-tables

  #:use-module (clojureism)

  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (ice-9 threads)
  #:use-module (ice-9 atomic)

  #:use-module (oop goops))

(define (current-desktop)
  (getenv "XDG_CURRENT_DESKTOP"))

(define chan
  (make-channel))

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

(define (get-interface class)
  (get-in (ref state) `(active-interfaces ,class)))

(define i get-interface) ;; shorten

(define (activate-interface! x)
  (swap! state (lambda (s) (assoc-in s `(active-interfaces ,(class-of x)) x))))

(define (deactivate-interface! x)
  (swap! state (lambda (s) (assoc-in s `(active-interfaces ,(class-of x)) #f))))

(define (catch-keymap keymap)
  (swap! state (lambda (s) (assoc s 'keymap keymap))))

(define (releasers)
  (alist->hash-table
    `((,<zwp-input-method-manager-v2> . ,zwp-input-method-manager-v2-destroy)
      (,<zwp-input-method-v2> . ,zwp-input-method-v2-destroy))
    eq?))

(define* (release x #:key
           (releasers releasers))
  (let [(releaser (get (releasers) (class-of x)))]
    (when releaser (releaser x))
    (deactivate-interface! x)))

(define (sway:wrap-binder . args)
  (apply wrap-binder (append args (list #:versioning sway:versioning))))

(define touch-listener
  (make-listener <wl-touch-listener>))

(define pointer-listener
  (make-listener <wl-pointer-listener>))

(define seat-listener
  (make-listener <wl-seat-listener>))

(define registry:required-interfaces
 '("wl_compositor"
   "wl_seat"
   "zwp_input_method_manager_v2"
   "xdg_wm_base"))

(define registry-listener
  (make-listener <wl-registry-listener>
    (list #:global
      (lambda* args
        (match-let* [((data registry name interface version) args)]
          (format #t "interface: '~a', version: ~a, name: ~a ~%"
            interface version name)
         (when (member interface registry:required-interfaces)
          (catch (apply sway:wrap-binder args)))))
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
        (catch-keymap (apply get-keymap (drop args 2))))
      #:key handle-key-press)))

(define input-method-listener
  (make-listener <zwp-input-method-v2-listener>
    (list #:activate
      (lambda (_ im)
        (format #t "activate! im: ~a ~%" im)
        (catch-interface (wl-compositor-create-surface (i <wl-compositor>)))
        (catch-interface (zwp-input-method-v2-get-input-popup-surface im (i <wl-surface>)))
        (catch-interface (zwp-input-method-v2-grab-keyboard im)))
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
       (,<zwp-input-method-v2> . ,input-method-listener)) eq?))

(define* (add-listener* x #:key (listeners listeners))
  ;; NOTE: ares will fail to eval if (listeners) are not dynamic call
  (let [(listener (get (listeners) (class-of x)))]
    (when listener (add-listener x listener)) #t))

(define* (catch x #:key (listeners listeners))
  (format #t "Catch* ~a into current state ~a ~%" x (ref state))
  (cond
    ;; interface already active
    ((i (class-of x)) (release x))
    ;; x if false := failed to get it (for example devices won't have touch capability)
    ((equal? #f x) #f)
    (else (activate-interface! x)
          (add-listener* x #:listeners listeners))))

(define (main)
  (catch (wl-display-connect))

  (unless (i <wl-display>)
    (display "Unable to connect to wayland compositor")
    (newline)
    (exit -1))

  (catch (wl-display-get-registry (i <wl-display>)))

  ;; roundtip here is needed to catch* all the interfaces inside registry-listener
  ;; https://wayland.freedesktop.org/docs/html/apb.html#Client-classwl__display_1ab60f38c2f80980ac84f347e932793390
  (wl-display-roundtrip (i <wl-display>))

  (if (i <zwp-input-method-manager-v2>)
    (format #t "Input manager available: ~a ~%" (i <zwp-input-method-manager-v2>))
    (error (format #f "Can't access input-manager!")))

  (catch (zwp-input-method-manager-v2-get-input-method
           (i <zwp-input-method-manager-v2>)
           (i <wl-seat>)))

  (format #t "Input-method: ~a ~%" (i <zwp-input-method-v2>))

  (while #t (wl-display-roundtrip (i <wl-display>))))

(define output-file (make-parameter "./output.txt"))

(define (reset-output)
  (when (file-exists? (output-file))
    (delete-file (output-file))))

(define output-port (open-file (output-file) "a0"))

(define thread
  (call-with-new-thread
   (lambda ()
     (with-output-to-port output-port main))))

;; (cancel-thread thread)

#|
(zwp-input-method-v2-commit-string (ref input-method) "Lorem ipsum")
(zwp-input-method-v2-commit (ref input-method) 1)
|#
