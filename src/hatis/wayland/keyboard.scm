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
     (let* [(bytevector-keymap (mmap
                                #f size
                                (logior PROT_READ PROT_WRITE)
                                MAP_PRIVATE fd 0))
            ;; TODO: munmap? memory safety?
            (keymap (utf8->string bytevector-keymap))]
       (format* #t "keymap: ~a ~%" keymap)
       keymap))))
