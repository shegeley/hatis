(define-module (hatis wayland keyboard)
  #:use-module (hatis utils)

  #:use-module (ice-9 match)

  #:export (get-keymap
            keycode:evdev->xkb))

(define (get-keymap format fd _)
  "Read keymap from `fd' (file descriptor) as a string in xkb format"
  (match format
    (0 'no-keymap)
    (1 (read-string-from-fd fd))
    (_ 'unknown)))

(define (keycode:evdev->xkb keycode)
  "Translates evdev keycode to xkb keycode"
  (+ keycode 8))
