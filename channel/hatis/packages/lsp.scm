(define-module (hatis packages lsp)
 #:use-module (guix packages)
 #:use-module (guix build-system asdf)
 #:use-module (guix download)
 #:use-module (gnu packages lisp-xyz)
 #:use-module (guix build-system copy)
 #:use-module (gnu packages readline)
 #:use-module (guix git-download)
 #:use-module ((guix licenses) #:prefix license:))

(define-public sbcl-alive-lsp
  (package
    (name "sbcl-alive-lsp")
    (version "0.2.11")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/nobody-famous/alive-lsp")
             (commit (string-append "v" version))))
       (file-name (git-file-name "sbcl-alive-lsp" version))
       (sha256
        (base32 "1dmgglrg7294vx8qacc5d2hkhfrids1iacihj2l8czrvwc3i19yz"))))
    (build-system asdf-build-system/sbcl)
    (inputs
     (list sbcl-usocket
           sbcl-cl-json
           sbcl-bordeaux-threads
           sbcl-flexi-streams))
    (home-page "https://github.com/nobody-famous/alive-lsp")
    (synopsis "Common Lisp Alive LSP")
    (description "Language Server Protocol implementation for use with the
    @url{https://github.com/nobody-famous/alive, Alive} Visual Studio Code extension")
    (license license:unlicense)))
