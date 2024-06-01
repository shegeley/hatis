(define-module (packages wlroots)
 #:use-module (guix packages)
 #:use-module ((guix licenses) #:prefix license:)
 #:use-module (guix download)
 #:use-module (gnu packages freedesktop)
 #:use-module (guix git-download)
 #:use-module (guix gexp)

 #:use-module (guix build-system gnu)
 #:use-module (guix build-system meson)

 #:use-module (gnu packages pciutils)
 #:use-module (gnu packages autotools)
 #:use-module (gnu packages linux)
 #:use-module (gnu packages xdisorg)
 #:use-module (gnu packages gl)
 #:use-module (gnu packages package-management)
 #:use-module (gnu packages admin)
 #:use-module (gnu packages xorg)
 #:use-module (gnu packages pkg-config)
 #:use-module (gnu packages texinfo))

(define-public wlroots
  ;; NOTE: had to rewrite to export XML protocols to reference them later
  (let [(expose-protocols
         `(lambda* (#:key inputs outputs #:allow-other-keys)
            (mkdir-p "protocols")
            (copy-recursively
             "protocol" ;; why singular?!
             (string-append (assoc-ref outputs "out")
                            "/protocols")
             #:copy-file (lambda (x y)
                           (if (string-suffix-ci? ".xml" x)
                               (copy-file x y)
                               (lambda (x y) #f)))) #t))]
    (package
      (name "wlroots")
      (version "0.16.2")
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://gitlab.freedesktop.org/wlroots/wlroots")
               (commit version)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1m12nv6avgnz626h3giqp6gcx44w1wq6z0jy780mx8z255ic7q15"))))
      (build-system meson-build-system)
      (arguments
       `(#:phases
         (modify-phases %standard-phases
           (add-before 'configure 'hardcode-paths
             (lambda* (#:key inputs #:allow-other-keys)
               (substitute* "xwayland/server.c"
                 (("Xwayland")
                  (string-append
                   (assoc-ref inputs "xorg-server-xwayland")
                   "/bin/Xwayland")))
               #t))
           (add-before 'configure 'fix-meson-file
             (lambda* (#:key native-inputs inputs #:allow-other-keys)
               (substitute* "backend/drm/meson.build"
                 (("/usr/share/hwdata/pnp.ids")
                  (string-append (assoc-ref (or native-inputs inputs) "hwdata")
                                 "/share/hwdata/pnp.ids")))))
           (add-before 'configure 'expose-protocols
             ,expose-protocols))))
      (propagated-inputs
       (list ;; As required by wlroots.pc.
        eudev
        libinput-minimal
        libxkbcommon
        mesa
        pixman
        libseat
        wayland
        wayland-protocols
        xcb-util-errors
        xcb-util-wm
        xorg-server-xwayland))
      (native-inputs
       (cons*
        `(,hwdata "pnp")
        pkg-config
        wayland
        (if (%current-target-system)
            (list pkg-config-for-build)
            '())))
      (home-page "https://gitlab.freedesktop.org/wlroots/wlroots/")
      (synopsis "Pluggable, composable, unopinionated modules for building a
Wayland compositor")
      (description "wlroots is a set of pluggable, composable, unopinionated
modules for building a Wayland compositor.")
      (license license:expat))))
