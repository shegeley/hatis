(defpackage :xyz.hatis.core
 (:use
  :wayflan-client

  :xyz.hatis.protocols.data-control
  :xyz.hatis.protocols.input-method
  :xyz.hatis.protocols.foreign-toplevel-management

  :xyz.hatis.utils

  :chanl
  :access
  :arrows
  :cl)
 (:import-from :wayflan-client :%proxy-table)
 (:local-nicknames
  (:a :alexandria)
  (:t :trivia)))

(in-package :xyz.hatis.core)

(defparameter *channel* (make-instance 'channel))

(defun get-interface (type)
  "keep in mind that there can be multiple interfaces of the same time in display's proxy-table. find-if only returns first"
 (->>
   '%proxy-table
   (slot-value *display*)
   (a:hash-table-values)
   (find-if (lambda (x) (eq type (type-of x))))))

(defparameter key->code
 `((Esc . 1)))

(defun assoc-ref (alist k) (cdr (assoc k alist)))

(defparameter *display* nil)

(defvar registry-global-interfaces-bind-list
 ;; "List of 'initial' (:= coming from the registry) interfaces that's needed by hatis"
 `(wl-seat
   zwp-input-method-manager-v2
   zwlr-foreign-toplevel-manager-v1))

(defmethod handle-interface-event (i e) (lambda (&rest args) args))

(defmethod handle-interface-event
 ((i zwlr-foreign-toplevel-manager-v1) (e (eql :toplevel)))
 (lambda (handle) (process-interface handle)))

(defmethod handle-interface-event
 ((i zwp-input-method-keyboard-grab-v2) (e (eql :keymap)))
 (lambda (&rest args) ;; (serial time key state)
  (cons :keymap args)))

(defmethod handle-interface-event
 ((i zwp-input-method-keyboard-grab-v2) (e (eql :key)))
 (lambda (serial time keycode state)
 (cond
   ((= (assoc-ref key->code `Esc) keycode)
    (let ((imkg (get-interface 'zwp-input-method-keyboard-grab-v2)))
     (format t "Releasing keyboard grab ~a ~%" imkg)
     (zwp-input-method-keyboard-grab-v2.release imkg)))
  (t (list serial time keycode state)))))

(defmethod handle-interface-event
 ((i zwp-input-method-keyboard-grab-v2) (e (eql :modifiers)))
 (lambda (&rest args)
  ;; (serial time key state)
  (cons :modifiers args)))

(defmethod handle-interface-event
 ((i zwp-input-method-v2) (e (eql :activate)))
 (lambda ()
  (let ((grab (zwp-input-method-v2.grab-keyboard i)))
   (process-interface grab))))

(defmethod handle-interface-event
 ((i zwp-input-method-v2) (e (eql :deactivate)))
 (lambda ()
  (let ((grab (get-interface 'zwp-input-method-keyboard-grab-v2)))
   (when grab
    (zwp-input-method-keyboard-grab-v2.release grab)
    (list 'deactivated 'zwp-input-method-keyboard-grab-v2)))))

(defmethod handle-interface-event
    ((i zwp-input-method-v2) (e (eql :content-type)))
  ;; EXAMPLE (CONTENT-TYPE (NONE) TERMINAL)
  (lambda (_ type)
    (cond ((eql type :terminal)
           "do something given it's a terminal"))))

(defmethod handle-interface-event
 ((registry wl-registry) (e (eql :global)))
 (lambda (id interface version)
  (let ((sinterface (interface-string->symbol interface)))
   (if (find sinterface registry-global-interfaces-bind-list)
    (let ((interface-object (bind registry id interface version)))
     (process-interface interface-object))
    (list 'wl-registry 'global (list id interface version))))))

(defun handle-interface-event*
 (interface event &key (channel *channel*))
 "Handle wayland's interface event according to the handle-interface-event method and send result to the channel"
 (destructuring-bind (event-name &rest event-args) event
  (let ((r (apply (handle-interface-event interface event-name) event-args)))
   (send channel (cons 'wayland-interface-event event))
   (send channel (cons 'handled-event-result r)))))

(defun install-event-handlers! (interface)
 (push
  (lambda (event) (handle-interface-event* interface event))
  (wl-proxy-hooks interface)))

(defun bind (registry id interface version)
 (wl-registry.bind registry id (interface-string->symbol interface) version))

(defmethod process-interface
 ((d wl-display))
  (progn
    (setq *display* d)
    (process-interface (wl-display.get-registry *display*))
    ;; double roundrtip needed to catch all the interfaces + toplevel manager&handle
    (wl-display-roundtrip *display*)
    (wl-display-roundtrip *display*)))

(defmethod process-interface
 (interface)
 "This method is called BEFORE all the interfaces are 'collected' into *state* hashtable. So you can't rely on it's being filled on this method's first call"
 (progn
  (install-event-handlers! interface)
  (list 'processed interface)))

(defun get-input-method ()
  (let* ((imm  (get-interface 'zwp-input-method-manager-v2))
         (im   (get-interface 'zwp-input-method-v2))
         (seat (get-interface 'wl-seat)))
    (if im im (zwp-input-method-manager-v2.get-input-method imm seat))))

(defun start! ()
 (print "Starting hatis…") (terpri)
 (with-open-display (display)
   (pexec () (loop (format t "~a~%" (recv *channel*))))
   (process-interface display)
   (process-interface (get-input-method))
   (loop
     (if (not (eql 'wl-destroyed-proxy (type-of *display*)))
         (wl-display-dispatch-event *display*)
         (return t)))))

(defun stop! ()
 (handler-case
  (progn
   (print "Stopping hatis…") (terpri)
   (wl-display.sync *display*)
   (wl-display-disconnect *display*))
  (error (c)
   (print "Coudn't stop hatis…") (terpri)
   (format *error-output* "Caught error: ~a ~%" c)
   nil)))

;; (start!)
;; (stop!)
