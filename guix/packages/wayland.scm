(define-module (packages wayland)
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
  #:use-module (gnu packages xml)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages python)

  #:use-module (gnu packages package-management)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages texinfo))

(define-public wayland/latest
 (package
  (inherit wayland)
  (version "1.23.1")
  (source (origin
           (method git-fetch)
           (uri (git-reference
                 (url "https://gitlab.freedesktop.org/wayland/wayland")
                 (commit version)))
           (sha256 (base32 "0jcjx1r25cyzdckm05wb3n1047ifgrwxh49vdwz4dvygfnvjvll8"))))))

wayland/latest
