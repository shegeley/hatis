(defpackage :xyz.hatis.ui.text-view
 (:use
  :xyz.hatis.utils
  :gtk
  :chanl
  :access
  :arrows
  :cl))

(in-package #:xyz.hatis.ui.text-view)

(defvar C (make-instance 'channel))

#| GtkTextBuffer* gtk_text_buffer_new (GtkTextTagTable* table) |#
#| see: arguments translated as keywords |#
(defvar text-buffer* (make-text-buffer :table nil))
(defvar app-id "xyz.hatis.gtk4.text-view")
(defvar window-title "Hatis Text View")
(defvar text-view-css "textview { font-size: 50px; }")

(define-application (:name simple-text-view :id app-id)
 (define-main-window (window (make-application-window :application *application*))

  (setf (window-title window) window-title)

  (let* ((css-provider* (make-css-provider))
         (window-box (make-box :orientation +orientation-vertical+ :spacing 0))
         (body-box (make-box :orientation +orientation-vertical+ :spacing 0))
         (scrolled-window (make-scrolled-window)))

   (setf
    (widget-hexpand-p scrolled-window) t
    (widget-vexpand-p scrolled-window) t)

   (let ((view (make-text-view)))
    (box-append body-box scrolled-window)

    (css-provider-load-from-string css-provider* text-view-css)
    (style-context-add-provider (widget-style-context view) css-provider* 1)

    (setf
     (scrolled-window-child scrolled-window) view
     (text-view-buffer view) text-buffer*
     (text-view-right-margin view) 20
     (text-view-left-margin view) 20
     (text-view-wrap-mode view) +wrap-mode-word-char+
     (text-buffer-text text-buffer*) "hello world"))

   (setf
    (widget-size-request body-box) '(400 200)
    (window-child window) window-box)
   (box-append window-box body-box))

  (unless (widget-visible-p window)
   (window-present window))))


#|
;; evaling 2 forms below will insert "kek" into text-buffer. still needs investigation on how it works.
;; also: gtk in single threaded. chanl has it's own threadpool?
(send C "kek")
(pexec ()
 (text-buffer-insert
  text-buffer*
  (text-buffer-end-iter text-buffer*)
  (recv C)))
|#

;; (pexec () (simple-text-view))
