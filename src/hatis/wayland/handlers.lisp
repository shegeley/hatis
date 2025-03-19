(defpackage :xyz.hatis.wayland.handlers
 (:use
  :wayflan-client

  :xyz.hatis.protocols.data-control
  :xyz.hatis.protocols.input-method
  :xyz.hatis.protocols.foreign-toplevel-management

  :xyz.hatis.utils
  :xyz.hatis.classes

  :chanl
  :cl)
 (:import-from :wayflan-client :%proxy-table)
 (:import-from :xyz.hatis.classes :Hatis)
 (:import-from :xyz.hatis.classes :%display)
 (:import-from :xyz.hatis.classes :%channel)
 (:export :install-event-handlers!))

(in-package :xyz.hatis.wayland.handlers)

(defparameter key->code
 `((Esc . 1)))

(defun assoc-ref (alist k) (cdr (assoc k alist)))

(defvar registry-global-interfaces-bind-list
 ;; "List of 'initial' (:= coming from the registry) interfaces that's needed by hatis"
 `(wl-seat
   zwp-input-method-manager-v2
   zwlr-foreign-toplevel-manager-v1))

(defun bind (registry id interface version)
  (wl-registry.bind registry id
   (interface-string->symbol interface) version))

(defmethod handle-interface-event (h i e) (lambda (&rest args) args))

(defmethod handle-interface-event
 ((H Hatis) (i zwlr-foreign-toplevel-manager-v1) (e (eql :toplevel)))
 (lambda (handle) handle))

(defmethod handle-interface-event
 ((H Hatis) (i zwp-input-method-keyboard-grab-v2) (e (eql :keymap)))
 (lambda (&rest args) ;; (serial time key state)
  (cons :keymap args)))

(defun keyboard-grab-quit (H)
 (let* ((class 'zwp-input-method-keyboard-grab-v2)
        (imkg (get-interface H class)))
  (zwp-input-method-keyboard-grab-v2.release imkg)))

(defun escp (keycode) (= (assoc-ref key->code `Esc) keycode))

(defmethod handle-interface-event
 ((H Hatis) (i zwp-input-method-keyboard-grab-v2) (e (eql :key)))
 (lambda (serial time keycode state)
  (cond
   ((escp keycode) (keyboard-grab-quit H))
   (t (list serial time keycode state)))))

(defmethod handle-interface-event
 ((H Hatis) (i zwp-input-method-keyboard-grab-v2) (e (eql :modifiers)))
 (lambda (&rest args) ;; (serial time key state)
  (cons :modifiers args)))

(defmethod handle-interface-event
 ((H Hatis) (i zwp-input-method-v2) (e (eql :activate)))
 (lambda ()
  (zwp-input-method-v2.grab-keyboard i)))

(defmethod handle-interface-event
 ((H Hatis) (i zwp-input-method-v2) (e (eql :deactivate)))
 (lambda ()
  (let ((grab (get-interface H 'zwp-input-method-keyboard-grab-v2)))
   (when grab
    (zwp-input-method-keyboard-grab-v2.release grab)
    (list 'deactivated 'zwp-input-method-keyboard-grab-v2)))))

(defmethod handle-interface-event
 ((H Hatis) (i zwp-input-method-v2) (e (eql :content-type)))
  ;; EXAMPLE (CONTENT-TYPE (NONE) TERMINAL)
  (lambda (_ type)
   (cond
    ((eql type :terminal)
     "do something given it's a terminal"))))

(defmethod handle-interface-event
 ((H Hatis) (registry wl-registry) (e (eql :global)))
 (lambda (id interface-string version)
  (let ((sinterface (interface-string->symbol interface-string)))
   (if (find sinterface registry-global-interfaces-bind-list)
    (let ((interface (bind registry id interface-string version)))
     (list 'wayland-interface interface))
    (list :global (list id sinterface version))))))

(defun handle-interface-event*
 (H interface event)
 "Handle wayland's interface event according to the handle-interface-event method and send result to the channel"
 (with-slots ((channel xyz.hatis.classes::channel)) H
  (destructuring-bind (event-name &rest event-args) event
   (let ((r (apply
             (handle-interface-event H interface event-name)
             event-args)))
    (format t "result: ~a ~%" r)
    (send channel
     (append (list 'wayland-event interface) event)
     :blockp nil)
    (cond
     ((typep r 'wl-proxy)
      (install-event-handlers! H r))
     (t
      (send channel (list 'wayland-event-result r)
       :blockp nil)))))))

(defun install-event-handlers!
 (H interface)
 (push
  (lambda (event) (handle-interface-event* H interface event))
  (wl-proxy-hooks interface)))
