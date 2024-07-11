(define-module (wayland client protocol input-method)
  #:use-module (wayland client protocol wayland)
  #:use-module (bytestructure-class)
  #:use-module (wayland scanner)
  #:use-module (wayland config))

(use-wayland-protocol ("input-method-unstable-v2.xml"
                       #:type client))
