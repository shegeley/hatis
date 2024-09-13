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

 #:use-module (packages bytestructure-class))

(define url    "https://github.com/guile-wayland/guile-wayland")
(define commit "f56a60c25494126e94e5a098c4ec69da6c1425b9")
(define hash   "08jwa73sqcmf8cxgjcz67av7i0z7sk0r93wk7h9wgb1c8730ilgi")

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
