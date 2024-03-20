(define-module (hatis wayland keyboard)

  #:use-module ((ice-9 format)
                #:select ((format . format*)))
  #:use-module (ice-9 match)
  #:use-module (ice-9 binary-ports)

  #:use-module (rnrs bytevectors)

  #:export (get-keymap
            keycode:evdev->xkb))

(define (get-keymap format fd size)
  (match format
    (0 'no-keymap)
    (1
     (let* [(bytevector-keymap (get-bytevector-all (fdopen fd "rb")))
            (keymap (utf8->string bytevector-keymap))]
       keymap))
    (_ 'unknown)))

(define (keycode:evdev->xkb keycode)
  "Translates evdev keycode to xkb keycode"
  (+ keycode 8))
