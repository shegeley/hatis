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

(defparameter app nil)

(defparameter key->code
 `((Esc . 1)))

(defun assoc-ref (alist k) (cdr (assoc k alist)))

(defvar registry-global-interfaces-bind-list
 ;; "List of 'initial' (:= coming from the registry) interfaces that's needed by hatis"
 `(wl-seat
   zwp-input-method-manager-v2
   zwlr-foreign-toplevel-manager-v1))

(defclass Hatis ()
 ((display :type wl-display
   :initarg :display
   :accessor %display)
  (channel :type channel
   :initarg :channel
   :accessor %channel)))

(defmethod get-interface
 ((display wl-display) type)
 (->>
  '%proxy-table
  (slot-value display) (a:hash-table-values)
  (find-if (lambda (x) (eq type (type-of x))))))

(defmethod get-interface
 ((H Hatis) type) (get-interface (%display H) type))

(defmethod get-input-method ((display wl-display))
 (let* ((gim  #'zwp-input-method-manager-v2.get-input-method)
        (imm  (get-interface display 'zwp-input-method-manager-v2))
        (im   (get-interface display 'zwp-input-method-v2))
        (seat (get-interface display 'wl-seat)))
  (cond
   (im im)
   ((and imm seat) (funcall gim imm seat))
   (t (signal 'cannot-get-input-method)))))

(defmethod get-input-method ((H Hatis))
 (with-slots (display) H (get-input-method display)))

(defun bind (registry id interface version)
 (wl-registry.bind registry id
  (interface-string->symbol interface) version))

(defmethod handle-interface-event (h i e) (lambda (&rest args) args))

(defmethod handle-interface-event
 (_ (i zwlr-foreign-toplevel-manager-v1) (e (eql :toplevel)))
 (lambda (handle) handle))

(defmethod handle-interface-event
 (_ (i zwp-input-method-keyboard-grab-v2) (e (eql :keymap)))
 (lambda (&rest args) ;; (serial time key state)
  (cons :keymap args)))

(defmethod handle-interface-event
 ((H Hatis) (i zwp-input-method-keyboard-grab-v2) (e (eql :key)))
 (lambda (serial time keycode state)
 (cond
   ((= (assoc-ref key->code `Esc) keycode)
    (let ((imkg (get-interface H 'zwp-input-method-keyboard-grab-v2)))
     (zwp-input-method-keyboard-grab-v2.release imkg)))
  (t (list serial time keycode state)))))

(defmethod handle-interface-event
 (_ (i zwp-input-method-keyboard-grab-v2) (e (eql :modifiers)))
 (lambda (&rest args) ;; (serial time key state)
  (cons :modifiers args)))

(defmethod handle-interface-event
 ((H hatis) (i zwp-input-method-v2) (e (eql :activate)))
 (lambda ()
  (let ((grab (zwp-input-method-v2.grab-keyboard i)))
   (process-interface H grab))))

(defmethod handle-interface-event
 ((H Hatis) (i zwp-input-method-v2) (e (eql :deactivate)))
 (lambda ()
  (let ((grab (get-interface H 'zwp-input-method-keyboard-grab-v2)))
   (when grab
    (zwp-input-method-keyboard-grab-v2.release grab)
    (list 'deactivated 'zwp-input-method-keyboard-grab-v2)))))

(defmethod handle-interface-event
 (_ (i zwp-input-method-v2) (e (eql :content-type)))
  ;; EXAMPLE (CONTENT-TYPE (NONE) TERMINAL)
  (lambda (_ type)
   (cond
    ((eql type :terminal)
     "do something given it's a terminal"))))

(defmethod handle-interface-event
 ((H Hatis) (registry wl-registry) (e (eql :global)))
 (lambda (id interface version)
  (let ((sinterface (interface-string->symbol interface)))
   (if (find sinterface registry-global-interfaces-bind-list)
    (let ((interface-object (bind registry id interface version)))
     (process-interface H interface-object))
    (list 'wl-registry 'global (list id interface version))))))

(defun handle-interface-event*
 (H interface event)
 "Handle wayland's interface event according to the handle-interface-event method and send result to the channel"
 (with-slots (channel) H
  (destructuring-bind (event-name &rest event-args) event
   (let ((r (apply (handle-interface-event H interface event-name)
             event-args)))
    (cond
     ((typep r 'wl-proxy) (process-interface H r))
     (t
      (send channel (cons 'wayland-interface-event event))
      (send channel (cons 'handled-event-result r))))))))

(defun install-event-handlers! (H interface)
 (push
  (lambda (event) (handle-interface-event* H interface event))
  (wl-proxy-hooks interface)))

(defmethod process-interface
 (H (d wl-display))
 (progn
  (process-interface H (wl-display.get-registry d))
  ;; double roundrtip needed to catch all the interfaces + toplevel manager&handle
  (wl-display-roundtrip d) (wl-display-roundtrip d)))

(defmethod process-interface
 (H interface)
 "This method is called BEFORE all the interfaces are 'collected' into %proxy-table. So you can't rely on it's being filled on this method's first call"
 (with-slots (channel) H
  (format t "processing: ~a ~%" interface)
  (send channel (list 'processing interface))
  (install-event-handlers! H interface)
  (list 'processed interface)))

(defun start! ()
 (print "Starting hatis…") (terpri)
 (with-open-display (display*)
  (let ((hatis (make-instance 'Hatis
                :display display*
                :channel (make-instance 'channel))))
   (setq app hatis)
   (with-slots (display channel) hatis
    (pexec () (loop (format t "~a~%" (recv channel))))
    (process-interface hatis display*)
    (process-interface hatis (get-input-method hatis))
    (loop
     (if (not (eql 'wl-destroyed-proxy (type-of display)))
      (wl-display-dispatch-event display)
      (return t)))))))

(defun stop! ()
 (handler-case
  (progn
   (print "Stopping hatis…") (terpri)
   (wl-display.sync (%display app))
   (wl-display-disconnect (%display app)))
  (error (c)
   (print "Coudn't stop hatis…") (terpri)
   (format *error-output* "Caught error: ~a ~%" c)
   nil)))

;; (stop!)
;; (start!)
