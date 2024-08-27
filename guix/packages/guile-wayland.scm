(define-module (packages guile-wayland)
 #:use-module ((guix licenses) #:prefix license:)
 #:use-module (guix download)
 #:use-module (guix gexp)
 #:use-module (guix git-download)
 #:use-module (guix packages)

 #:use-module (guix build-system gnu)
 #:use-module (guix build-system guile)
 #:use-module (guix build-system meson)

 #:use-module (gnu packages autotools)
 #:use-module (gnu packages build-tools)
 #:use-module (gnu packages freedesktop)
 #:use-module (gnu packages guile)
 #:use-module (gnu packages guile-xyz)
 #:use-module (gnu packages linux)
 #:use-module (gnu packages package-management)
 #:use-module (gnu packages pkg-config)
 #:use-module (gnu packages texinfo)

 #:use-module (packages bytestructure-class)
 #:use-module (packages wlroots))

(define url "https://github.com/guile-wayland/guile-wayland")
(define commit "cf96a8a5d710addb330021c1d3b21738447b2efb")
(define hash "1p07qs7pkkbhqa6568pfr44m1q1f783vh0a7nixhsmfpnv2fg8qr")

(define-public guile-wayland
 (package
  (name "guile-wayland")
  (version "0.0.2")
  (source
   (origin
    (method git-fetch)
    (uri (git-reference (url url) (commit commit)))
    (sha256 (base32 hash))))
  (build-system gnu-build-system)
  (arguments
   (list
    #:configure-flags '(list "--disable-static")
    #:make-flags '(list "GUILE_AUTO_COMPILE=0")
    #:phases
    #~(modify-phases %standard-phases
       (add-before 'build 'load-extension
        (lambda* (#:key outputs #:allow-other-keys)
         (let* ((out (assoc-ref outputs "out"))
                (lib (string-append out "/lib")))
          (invoke "make" "install"
           "-C" "libguile-wayland"
           "-j" (number->string
                 (parallel-job-count)))
          (substitute* (find-files "." "\\.scm$")
           (("\"libguile-wayland\"")
            (string-append "\"" lib "/libguile-wayland\"")))))))))
  (native-inputs
   (list
    autoconf
    automake
    libtool
    pkg-config
    texinfo
    guile-3.0-latest))
  (inputs
   (list
    guile-fibers ;; personal
    guix
    guile-3.0-latest
    wayland
    wayland-protocols))
  (propagated-inputs
   (list
    guile-bytestructure-class
    guile-bytestructures))
  (synopsis "Guile Wrappers for wayland")
  (description "Guile Scheme wrappers for Wayland with GOOPS and xml-parsing-code-generating macroses and GOOPS")
  (home-page "https://github.com/guile-wayland/guile-wayland")
  (license license:gpl3+)))

guile-wayland
