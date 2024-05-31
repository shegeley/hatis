(define-module (packages srfi srfi-125)
 #:use-module ((guix licenses) #:prefix license:)
 #:use-module (guix packages)
 #:use-module (guix git-download)
 #:use-module (guix download)
 #:use-module (guix utils)
 #:use-module (guix build-system guile)
 #:use-module (gnu packages guile)
 #:use-module (gnu packages guile-xyz)
 #:use-module (gnu packages package-management)

 #:use-module (packages srfi srfi-126))

(define-public guile-srfi-125
 (let [(commit "8f4942f0612b6cc6af56fc90146afcccfe67d85f")
       (hash "11fzpsjqlg2qd6gcxnsiy9vgisnw4d0gkh9wiarkjqyr3j95440q")
       (revision "1")]
  (package
   (name "guile-srfi-125")
   (version revision)
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/shegeley/srfi-125")
           (commit commit)))
     (sha256 (base32 hash))
     (snippet '(begin
                (rename-file "srfi/125.sld" "srfi/srfi-125.scm")
                (delete-file "tables-test.sps")
                #t))))
   (build-system guile-build-system)
   (inputs (list guile-3.0))
   (propagated-inputs (list guile-srfi-128 guile-srfi-126))
   (home-page "https://github.com/scheme-requests-for-implementation/srfi-125")
   (synopsis "SRFI 125: Intermediate hash tables")
   (description "The procedures in this SRFI are drawn primarily from SRFI 69 and R6RS. In addition, the following sources are acknowledged:
    - The hash-table-mutable? procedure and the second argument of hash-table-copy (which allows the creation of immutable hash tables) are from R6RS, renamed in the style of this SRFI.
    - The hash-table-intern! procedure is from Racket, renamed in the style of this SRFI.
    - The hash-table-find procedure is a modified version of table-search in Gambit.
    - The procedures hash-table-unfold and hash-table-count were suggested by SRFI 1.
    - The procedures hash-table=? and hash-table-map were suggested by Haskell's Data.Map.Strict module.
    - The procedure hash-table-map->list is from Guile.

    The procedures hash-table-empty?, hash-table-empty-copy, hash-table-pop!, hash-table-map!, hash-table-intersection!, hash-table-difference!, and hash-table-xor! were added for convenience and completeness. ")
   (license license:expat))))
