(define-module (packages srfi srfi-126)
 #:use-module ((guix licenses) #:prefix license:)
 #:use-module (guix packages)
 #:use-module (guix git-download)
 #:use-module (guix download)
 #:use-module (guix utils)
 #:use-module (guix build-system guile)
 #:use-module (gnu packages guile)
 #:use-module (gnu packages guile-xyz)
 #:use-module (gnu packages package-management))

(define-public guile-srfi-126
 (let [(commit "f480cf2d1a33c1f3d0fab3baf321c0ed5b5eb248")
       (revision "0")]
  (package
   (name "guile-srfi-126")
   (version revision)
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/scheme-requests-for-implementation/srfi-126")
           (commit commit)))
     (file-name (git-file-name name version))
     (modules '((guix build utils)))
     (snippet
      '(begin
        (delete-file-recursively "r6rs")

        (delete-file "srfi/126.sld")
        (delete-file "srfi/126.sld.in")
        (delete-file "srfi/:126.sls")
        (delete-file "srfi/:126.sls.in")

        (delete-file "test-suite.body.scm")
        (delete-file "test-suite.r6rs.sps")
        (delete-file "test-suite.r6rs.sps.in")
        (delete-file "test-suite.r7rs.scm")
        (delete-file "test-suite.r7rs.scm.in")
        #t))
     (sha256
      (base32 "18psw8l798xmbv2h90cz41r51q1mydzg7yr71krfprx5kdfqn32q"))))
   (build-system guile-build-system)
   (native-inputs (list guile-3.0))
   (home-page "https://github.com/scheme-requests-for-implementation/srfi-126")
   (synopsis "SRFI 126: R6RS-based hashtables")
   (description "The utility procedures provided by this SRFI in addition to the R6RS API may be categorized as follows:
    - Constructors: alist->eq-hashtable, alist->eqv-hashtable, alist->hashtable
    - Access and mutation: hashtable-lookup, hashtable-intern!
    - Copying: hashtable-empty-copy
    - Key/value collections: hashtable-values, hashtable-key-list, hashtable-value-list, hashtable-entry-lists
    - Iteration: hashtable-walk, hashtable-update-all!, hashtable-prune!, hashtable-merge!, hashtable-sum, hashtable-map->lset, hashtable-find
    - Miscellaneous: hashtable-empty?, hashtable-pop!, hashtable-inc!, hashtable-dec!")
   (license license:expat))))
