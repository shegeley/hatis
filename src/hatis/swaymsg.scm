(define-module (hatis swaymsg)
 #:use-module (ice-9 popen)
 #:use-module (ice-9 rdelim)

 #:use-module (hatis utils)

 #:export (get-toplevel change-toplevel!))

(define swaymsg:get-tree-command '("swaymsg" "-t" "get_tree"))

(define swaymsg:get-tree-command* (string-join swaymsg:get-tree-command " "))

(define (jq:arg-normalize sym)
 (string-append "." (-->_ (symbol->string sym))))

(define (jq:get-focused x)
 "@code{sym} can be 'app-id or 'pid"
 (list "jq" "\"" ".." "|" "select(.focused? == true)" "|" (jq:arg-normalize x) "\""))

(define (jq:get-focused* x) (string-join (jq:get-focused x) " "))

(define (get-toplevel x)
 "Dirty way of getting the current toplevel via 'swaymsg'. Should be replaced with zwlr-foreign-toplevel-management call as soon as that get fixed in guile-wayland or somehow else"
 (let* [(cmd (string-join (list swaymsg:get-tree-command* (jq:get-focused* x)) " | "))
        (port (open-input-pipe cmd))
        (str (read-line port))]
  (close-pipe port) str))

(define (change-toplevel! pid)
 "@code{pid} should be a string. Dirty way of chaning current toplevel (focused app). The alternative in zwlr-foreign-toplevel-management would be handle's 'activate' request"
 (system* "swaymsg" "[pid="pid"]" "focus"))
