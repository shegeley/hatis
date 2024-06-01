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
 #:use-module (gnu packages xdisorg)
 #:use-module (gnu packages)

 #:use-module (packages bytestructure-class)
 #:use-module (packages wlroots))

(define xmls-sources
  `(("wayland-protocols" . "/share/wayland-protocols")
    ("wlroots" . "/protocols")))

(define-public guile-wayland
 (let [(expose-protocols
        #~(lambda* (#:key inputs outputs #:allow-other-keys)
           (let* [(out (assoc-ref outputs "out"))
                  (xml-dir (string-append out "/xmls"))]
            (mkdir-p xml-dir)
            (map
             (lambda (x)
              (let [(xmls
                     (find-files
                      (string-append
                       (assoc-ref inputs (car x))
                       (cdr x))
                      (lambda (x _) (string-suffix-ci? ".xml" x))))]
               (map (lambda (x)
                     (copy-file
                      x
                      (string-append xml-dir "/" (basename x)))) xmls)))
             (quote #$xmls-sources))
            (substitute* "modules/wayland/config.scm.in"
             (("@WAYLAND_PROTOCOLS_DATAROOTDIR@") xml-dir))
            #t)))]
  (package
   (name "guile-wayland")
   (version "0.0.2")
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/shegeley/guile-wayland")
           (commit "19f8278dfe62c75985abe108c8aa6f559af0d964")))
     (sha256
      (base32 "1d4jz8mph8akhl3hwaic45a0qqzwlg7yg0kdkphxzyc9zvn8mza9"))))
   (build-system gnu-build-system)
   (arguments
    (list
     #:configure-flags '(list "--disable-static")
     #:make-flags '(list "GUILE_AUTO_COMPILE=0")
     #:phases
     #~(modify-phases %standard-phases
        (add-before 'configure 'expose-protocols
         #$expose-protocols)
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
     wayland-protocols
     wlroots))
   (propagated-inputs
    (list
     guile-bytestructure-class
     guile-bytestructures))
   (synopsis "Guile Wrappers for wayland")
   (description "Guile Scheme wrappers for Wayland with GOOPS and xml-parsing-code-generating macroses and GOOPS")
   (home-page "https://github.com/guile-wayland/guile-wayland")
   (license license:gpl3+))))
