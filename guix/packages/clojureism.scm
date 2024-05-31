(define-module (packages clojureism)
  #:use-module (gnu packages guile)

  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system guile)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)

  #:use-module (packages srfi srfi-125))

(define-public clojureism
 (let [(version "0.0.1")
       (hash "0gih45bx61vhnpl8bbmw3sxzfz4nxd2wm6qpm43xkfxn3kr2ajdj")]
  (package
   (name "clojureism")
   (version version)
   (source (origin
            (method git-fetch)
            (uri (git-reference
                  (url "https://github.com/shegeley/clojureism")
                  (commit (string-append "v" version))))
            (sha256 (base32 hash))))
   (build-system guile-build-system)
   (arguments (list #:source-directory "src"))
   (propagated-inputs (list guile-srfi-125))
   (native-inputs (list guile-3.0))
   (synopsis "Small guile scheme libriary to provide clojure-alike atom, vector and hash-map basic procedures")
   (description "The point of this small libriary is to mimic clojure's basic operations on data structures with guile scheme as close as possible.
Structures correspondence: vector [clojure] <-> vector [scheme], hash-map [clojure] <-> srfi-69 hash-table [scheme], atom [clojure] <-> ice-9 atomic [scheme].
Operations: get, get-in (vector, hash-table); assoc, assoc-in (vector, hash-table); update, update-in (vector, hash-table); ref, swap!, reset! (atomic).
Bonus: clojure-alike hash-table printer.")
   (license license:gpl3+)
   (home-page "https://github.com/shegeley/clojureism"))))
