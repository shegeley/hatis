(define-module (hatis wayland)
  #:use-module (wayland proxy)
  #:use-module (wayland interface)
  #:use-module (wayland client display)
  #:use-module (wayland client protocol input-method)
  #:use-module (wayland client protocol wayland)
  #:use-module (wayland client protocol xdg-shell)

  #:use-module (oop goops)
  #:use-module (ice-9 format))

;; (gc-disable) TODO: remove?

(define compositor
  (make-parameter #f))

(define display
  (make-parameter #f))

(define registry
  (make-parameter #f))

(define seat
  (make-parameter #f))

(define input-method-manager
  (make-parameter #f))

(define input-method
  (make-parameter #f))

(define input-surface
  (make-parameter #f))

(define keyboard
  (make-parameter #f))

(define registry-listener
  (make <wl-registry-listener>
    #:global
    (lambda* (data registry name interface version)
      (format #t "interface: '~a', version: ~a, name: ~a~%"
              interface version name)
      (cond
       ((string=? "wl_compositor" interface)
        (compositor (wrap-wl-compositor (wl-registry-bind registry name                      %wl-compositor-interface 3)))
        (input-surface (wl-compositor-create-surface (compositor))))
       ((string=? "wl_seat" interface)
        (seat (wrap-wl-seat (wl-registry-bind registry name %wl-seat-interface 3))))
       ((string=? "zwp_input_method_manager_v2" interface)
        (input-method-manager
         (wrap-zwp-input-method-manager-v2
          (wl-registry-bind registry name %zwp-input-method-manager-v2-interface 1))))))
    #:global-remove
    (lambda (data registry name)
      (pk 'remove data registry name))))

(define keyboard-grab-listener
  (make <zwp-input-method-keyboard-grab-v2-listener>
    #:release
    (lambda args
      (format #t "release! args: ~a ~%" args))
    #:keymap
    (lambda args
      (format #t "keymap! args: ~a ~%" args))
    #:modifiers
    (lambda args
      (format #t "modifiers! args: ~a ~%" args))
    #:repeat-info
    (lambda args
      (format #t "repeat-info! args: ~a ~%" args))
    #:key
    (lambda args
      (format #t "key! args: ~a ~%" args))))

(define input-method-listener
  (make <zwp-input-method-v2-listener>
    #:text-change-cause
    (lambda args
      (format #t "cause! args: ~a ~%" args))
    #:content-type
    (lambda args
      (format #t "content-type! args: ~a ~%" args))
    #:surrounding-text
    (lambda args
      (format #t "surrounding! args: ~a ~%" args))
    #:unavailable
    (lambda args
      (format #t "unavailable! args: ~a ~%" args))
    #:done
    (lambda args
      (format #t "done! args: ~a ~%" args))
    #:commit-string
    (lambda args
      (format #t "commit! args: ~a ~%" args))
    #:activate
    (lambda (_ im)
      (format #t "activate! im: ~a ~%" im)
      (keyboard (zwp-input-method-v2-grab-keyboard im))
      (zwp-input-method-keyboard-grab-v2-add-listener (keyboard) keyboard-grab-listener)
      ;; (zwp-input-method-v2-get-input-popup-surface
      ;;  (input-method)
      ;;  (input-surface))
      )
    #:deactivate
    (lambda args
      (format #t "leave! args: ~a ~%" args)
      (zwp-input-method-keyboard-grab-v2-release (keyboard)))))

(define (main)
  (display (wl-display-connect))
  (unless (display)
    (display "Unable to connect to wayland compositor")
    (newline)
    (exit -1))
  (format #t "Connect to Wayland compositor: ~a ~%" (display))
  (registry (wl-display-get-registry (display)))
  (wl-registry-add-listener (registry) registry-listener)
  (wl-display-roundtrip (display))
  (if (input-method-manager)
      (format #t "Got it!~%")
      (error (format #f "Can't access input-manager!")))
  (format #t "Input-method manager: ~a ~%" (input-method-manager))
  (input-method (zwp-input-method-manager-v2-get-input-method
                 (input-method-manager)
                 (seat)))
  (format #t "Input-method: ~a ~%" (input-method))
  (zwp-input-method-v2-add-listener (input-method) input-method-listener)
  (while (wl-display-roundtrip (display))))
