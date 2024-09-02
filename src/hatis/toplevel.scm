(define-module (hatis toplevel)
  #:use-module (wayland client display)
  #:use-module (wayland client protocol wayland)
  #:use-module (wayland interface)
  #:use-module (wayland client proxy)

  #:use-module (wayland client protocol input-method)
  ;; TODO: figure out why broken
  #:use-module (wayland client protocol foreign-toplevel-management)

  #:use-module (hatis wayland seat)
  #:use-module (hatis wayland keyboard)
  #:use-module (hatis wayland wrappers)
  #:use-module (hatis utils)


  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (ice-9 threads)
  #:use-module (ice-9 atomic)

  #:use-module (system foreign)

  #:use-module (oop goops))


(define w-display (wl-display-connect))

(define registry (wl-display-get-registry w-display))

(define toplevel-manager-listener
 (make <zwlr-foreign-toplevel-manager-v1-listener>
  #:toplevel (lambda args (pk args))
  #:finished (lambda args (pk args))))

(define p* (procedure->pointer void (lambda args (pk args)) (list '* '* '*)))

(define registry-listener
 (make <wl-registry-listener>
  #:global
  (lambda (data registry name interface version)
   (format #t "interface: '~a', version: ~a, name: ~a~%"
    interface version name)
   (if (string=? interface "zwlr_foreign_toplevel_manager_v1")
    (let [(toplevel-manager-proxy (wl-registry-bind
                             registry name
                             %zwlr-foreign-toplevel-manager-v1-interface
                             version))]
     (pk toplevel-manager-proxy)
     (wl-proxy-add-listener
      toplevel-manager-proxy
      (unwrap-zwlr-foreign-toplevel-manager-v1-listener toplevel-manager-listener)
      %null-pointer))))
  #:global-remove
  (lambda (data registry name)
   (format #t "removed: ~a~%" name))))

(wl-registry-add-listener registry registry-listener)

(wl-display-dispatch w-display)
