(defpackage :xyz.hatis.utils
 (:use
  :wayflan-client
  :arrows

  :xyz.hatis.classes
  :xyz.hatis.protocols.input-method
  :xyz.hatis.protocols.data-control

  :cl)
 (:import-from :xyz.hatis.classes :Hatis)
 (:import-from :xyz.hatis.classes :%display)
 (:import-from :xyz.hatis.classes :%channel)
 (:import-from :wayflan-client :%proxy-table)
 (:local-nicknames (:a :alexandria))
 (:export
  :_->- :wrap :force-output!
  :format! :interface-string->symbol
  :read-string
  :get-interface :get-input-method
  :get-data-control-device))

(in-package :xyz.hatis.utils)

(defun _->- (s) (substitute #\- #\_ s))

(defun read-string (stream)
 #| (format nil "~{~a~^, ~}" (list 1 2 3)) ==> "1, 2, 3"
    https://gigamonkeys.com/book/a-few-format-recipes |#
 (format nil "~{~a~^~%~}"
  (loop for line = (read-line stream nil)
   while line collect line)))

(defun wrap (wrapper proc &rest args)
 (apply wrapper args) (apply proc args) (apply wrapper args))

(defun interface-string->symbol (interface)
 (read-from-string (_->- interface)))

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
 (get-input-method (%display H)))

(defmethod get-data-control-device ((display wl-display))
 (let* ((seat (get-interface display 'wl-seat))
        (ddm (get-interface display 'zwlr-data-control-manager-v1))
        (gdd #'zwlr-data-control-manager-v1.get-data-device))
  (funcall gdd ddm seat)))

(defmethod get-data-control-device ((H Hatis))
  (get-data-control-device (%display H)))
