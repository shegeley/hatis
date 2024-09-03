 (define-module (packages wlroots)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix download)
  #:use-module (gnu packages freedesktop)
  #:use-module (guix git-download)
  #:use-module (guix gexp)

  #:use-module (guix build-system gnu)
  #:use-module (guix build-system meson)

  #:use-module ((gnu packages wm) #:select ((wlroots . wlroots-base)))
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages texinfo)

  #:use-module (guix transformations))

(define expose-protocols
 #~(lambda* (#:key inputs outputs #:allow-other-keys)
    (let* [(dir "share/wayland-protocols")
           (target-dir (string-append (assoc-ref outputs "out") "/" dir))
           (xml? (lambda (x) (string-suffix-ci? ".xml" x)))
           (xml-copy (lambda (x y) (if (xml? x) (copy-file x y) #f)))]
     (mkdir-p dir)
     (copy-recursively "protocol" target-dir #:copy-file xml-copy)
     (setenv "GUILE_WAYLAND_PROTOCOL_PATH" (string-append target-dir ":" (or "" (getenv "GUILE_WAYLAND_PROTOCOL_PATH"))))
     #t)))

(define-public wlroots
 (package
  (inherit wlroots-base)
  (native-search-paths
   (list (search-path-specification
          (variable "GUILE_WAYLAND_PROTOCOL_PATH")
          (files (list "share/wayland-protocols")))))
  (arguments
   (list #:phases
    #~(modify-phases %standard-phases
       (add-before 'configure 'hardcode-paths
        (lambda* (#:key inputs #:allow-other-keys)
         (substitute* "xwayland/server.c"
          (("Xwayland") (string-append (assoc-ref inputs "xorg-server-xwayland") "/bin/Xwayland"))) #t))
       (add-before 'configure 'fix-meson-file
        (lambda* (#:key native-inputs inputs #:allow-other-keys)
         (substitute* "backend/drm/meson.build"
          (("/usr/share/hwdata/pnp.ids")
           (string-append (assoc-ref (or native-inputs inputs) "hwdata")
            "/share/hwdata/pnp.ids"))) #t))
       (add-before 'configure 'expose-protocols #$expose-protocols))))))

wlroots
