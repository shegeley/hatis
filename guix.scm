(use-modules
 (guix packages)
 ((guix licenses) #:prefix license:)
 (guix download)
 (guix git-download)
 (guix gexp)
 (guix build-system guile)
 (gnu packages guile)
 (gnu packages guile-xyz)

 (packages guile-wayland)
 (packages bytestructure-class)
 (packages srfi srfi-125)
 (packages wlroots)
 (packages clojureism))

(define %source-dir (dirname (current-filename)))

(define-public hatis
  (package
    (name "hatis")
    (home-page "https://github.com/shegeley/hatis")
    (description "This is a very early-stage project (alpha-version) + a set of experiments of building HAckable Text Input System (HATIS)")
    (synopsis "")
    (arguments
     (list #:source-directory "."))
    (license license:gpl3+)
    (source (local-file "./wlsrc" "text-input-system-checkout" #:recursive? #t))
    (build-system guile-build-system)
    (version "0.0.1-alpha")
    (propagated-inputs (list
                         guile-wayland
                         clojureism
                         guile-srfi-125))
    (native-inputs (list wlroots guile-wayland))
    (inputs (list
             guile-fibers
             guile-websocket
             guile-3.0-latest))))

hatis
