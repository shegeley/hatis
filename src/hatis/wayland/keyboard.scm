(define-module (hatis wayland keyboard)

  #:use-module ((ice-9 format)
                #:select ((format . format*)))
  #:use-module (ice-9 match)

  #:use-module (rnrs bytevectors)

  #:use-module (mmap)

  #:export (get-keymap))

(define (get-keymap format fd size)
  (format* #t "get-keymap-args: ~a ~a ~a" format fd size)
  (match format
    (0 'no-keymap)
    (1
     ;; can be rewritten using: ~fdopen~ + ~(ice-9 binary-ports)~
     ;; https://www.gnu.org/software/guile/manual/html_node/Binary-I_002fO.html
     (let* [(bytevector-keymap (mmap
                                #f size
                                PROT_READ
                                MAP_PRIVATE fd 0))
            ;; TODO: munmap? memory safety?
            (keymap (utf8->string bytevector-keymap))]
       (format* #t "keymap: ~a ~%" keymap)
       keymap))))
