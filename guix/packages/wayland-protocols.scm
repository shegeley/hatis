(define-module (packages wayland-protocols)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix build-system guile)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-xyz)
  #:use-module (packages guile-wayland)
  #:use-module (packages wlroots))

(define-public hatis-wayland-protocols
  (package
    (name "wayland-protocols")
    (home-page "https://github.com/shegeley/hatis")
    (description "Wayland protocols for hatis")
    (synopsis "Wayland protocols for hatis")
    (arguments (list #:source-directory "."))
    (license license:gpl3+)
    (source (local-file "../../wayland-protocols"
              "hatis-wayland-protocols-checkout" #:recursive? #t))
    (build-system guile-build-system)
    (version "0.0.1")
    (propagated-inputs (list guile-3.0 wlroots guile-wayland))
    (inputs '())))

hatis-wayland-protocols
