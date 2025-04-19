(require 'lsp)
(require 'lsp-lisp)

(defun lsp-lisp-alive-start-ls ()
 "Start the alive-lsp."
 (interactive)
 (when-let (((lsp--port-available "localhost" lsp-lisp-alive-port)))
  (lsp-async-start-process #'ignore #'ignore
   (executable-find "guix")
   "shell"
   ;; TODO: remove when sbcl-alive-lsp is merged into guix
   ;; ↓ when having guix channel in your's project dir
   "-L" "channel"
   "sbcl"
   "sbcl-alive-lsp"
   "-D" "-f" "guix.scm"
   "--"
   "sbcl"
   "--eval"
   "(require :asdf)"
   "--eval"
   "(asdf:load-system :alive-lsp)"
   "--eval"
   (format "(alive/server::start :port %s)"
    lsp-lisp-alive-port))))

(lsp-lisp-alive-start-ls)
