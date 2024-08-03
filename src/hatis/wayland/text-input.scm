(define-module (hatis wayland text-input)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-125))

(define content-hints-table
  ;; "https://wayland.app/protocols/text-input-unstable-v3#zwp_text_input_v3:enum:content_hint"
  (alist->hash-table
   `((#x0 . none)
     (#x1 . completion)
     (#x2 . spellcheck)
     (#x3 . auto-capitalization)
     (#x8 . lowercase)
     (#x10 . uppercase)
     (#x20 . titlecase)
     (#x40 . hidden-text)
     (#x80 . sensitive-data)
     (#x100 . latin)
     (#x200 . multiline)) eqv?))

(define content-purpose-table
   ;; "https://wayland.app/protocols/text-input-unstable-v3#zwp_text_input_v3:enum:content_purpose"
  (alist->hash-table
   `((0 . normal)
     (1 . alphanumeric)
     (2 . digits)
     (3 . number)
     (4 . phone)
     (5 . url)
     (6 . email)
     (7 . name)
     (8 . password)
     (9 . pin)
     (10 . date)
     (11 . time)
     (12 . datetime)
     (13 . terminal)) eqv?))

(define (extract-content-hint value)
  (hash-table-ref/default content-hints-table value #f))

(define (extract-content-purpose value)
 (hash-table-ref/default content-purpose-table value #f))
