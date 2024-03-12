(define-module (hatis wayland keyboard)

  #:use-module ((ice-9 format)
                #:select ((format . format*)))

  #:use-module (ice-9 match)

  #:use-module (scheme base)
  #:use-module (mmap)

  #:export (get-keymap))

(define (get-keymap format fd size)
  (format* #t "get-keymap-args: ~a ~a ~a" format fd size)
  (match format
    (0  ;; do nothing?
     'no-keymap)
    (1 ;; should return bytevector
     (let [(keymap (mmap
                    #f size
                    (logior PROT_READ PROT_WRITE)
                    MAP_PRIVATE fd 0))]
       ;; TODO: munmap? memory safety?
       (format* #t "keymap: ~a ~%" keymap)))))
