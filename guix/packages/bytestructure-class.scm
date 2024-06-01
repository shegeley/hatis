(define-module (packages bytestructure-class)
 #:use-module (guix packages)
 #:use-module ((guix licenses) #:prefix license:)
 #:use-module (guix download)
 #:use-module (guix git-download)
 #:use-module (guix gexp)
 #:use-module (guix build-system gnu)
 #:use-module (gnu packages)
 #:use-module (gnu packages autotools)
 #:use-module (gnu packages guile)
 #:use-module (gnu packages guile-xyz)
 #:use-module (gnu packages linux)
 #:use-module (gnu packages gl)
 #:use-module (gnu packages package-management)
 #:use-module (gnu packages admin)
 #:use-module (gnu packages pkg-config)
 #:use-module (gnu packages texinfo)
 #:use-module (gnu packages build-tools))

(define-public guile-bytestructure-class
  (package
    (name "guile-bytestructure-class")
    (version "0.2.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/Z572/guile-bytestructure-class")
                    (commit "2cdb25c445e87c3d9e7e1a169a3ea3c476f373e3")))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0y3sryy79arp3f5smyxn8w7zra3j4bb0qdpl1p0bld3jicc4s86a"))))
    (build-system gnu-build-system)
    (arguments
     (list #:make-flags #~'("GUILE_AUTO_COMPILE=0")))
    (native-inputs
     (list autoconf
           automake
           pkg-config
           guile-3.0-latest))
    (inputs (list guile-3.0-latest))
    (propagated-inputs (list guile-bytestructures))
    (synopsis "bytestructure and goops")
    (description "This package combines bytestructure with goops,
and provide 4 new bytestructure-descriptor:
bs:unknow, cstring-pointer*, bs:enum, stdbool.")
    (home-page "https://github.com/Z572/guile-bytestructure-class")
    (license license:gpl3+)))
