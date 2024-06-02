(define-module (hatis sway)

  #:use-module (srfi srfi-125) ;; hash-tables

  #:export (versioning))

;; Maybe it's a bad idea to directly keep knowledge of sway's wayland interfaces versioning inside hatis...
;; It would be better to teach guile-wayland read versions directly from XMLs (why it won't do so???)

(define versioning
  (alist->hash-table
   `((wl-compositor . 3)
     (wl-seat . 3)
     (zwp-input-method-manager-v2 . 1)
     (xdg-wm-base . 2))
   equal?))
