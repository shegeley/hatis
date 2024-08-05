(define-module (wayland client protocol foreign-toplevel-management)
 #:use-module (wayland client protocol wayland)
 #:use-module (wayland client display)

 #:use-module (wayland interface)
 #:use-module (wayland client proxy)

 #:use-module (bytestructure-class)
 #:use-module (wayland scanner)
 #:use-module (wayland config))

(use-wayland-protocol ("wlr-foreign-toplevel-management-unstable-v1.xml"
                       #:type client))
