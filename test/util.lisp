
(declaim (optimize (debug 3)))

(in-package :arc/test)

;;; Test utils

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *tests* nil))

(defvar *curr* '(nil . 0))
(defvar *failed* nil)

(defgeneric == (a b)
  (:method (a b) (equal a b)))

(defmacro deftest (name &body body)
  `(progn
     (eval-when (:compile-toplevel :load-toplevel :execute)
       (pushnew ',name *tests*))
     (defun ,name ()
       (setf *curr* (cons ',name 1))
       (format t "~a~15t " ',name)
       (macrolet ((_e (x) `(arcev ',x))) ,@body)
       (terpri))))
     
(defun chk (res)
  (princ (if res #\. #\+))
  (when (not res) (push (copy-list *curr*) *failed*))
  (incf (cdr *curr*)))

(defun arc-read-form (str)
  (with-input-from-string (s str)
    (w/no-colon (read s))))

(macrolet ((_chk (name fn)
	     `(defun ,name (res str)
		(chk (== res 
			 (ignore-errors
			   (,fn (arc-read-form str))))))))
  (_chk chkmac arcmac)
  (_chk chkc   arcc)
  (_chk chkev  arcev))

(defun chkerr (str)
  (chk (handler-case (arcev (arc-read-form str))
	 (error () t)
	 (:no-error (res) 
	   (declare (ignore res)) 
	   nil))))

(defun run (&rest which)
  (flet ((in-arc (sym)
	   (intern (symbol-name sym))))
    (let ((tests (if which 
		     (mapcar #'in-arc which)
		     (reverse *tests*))))
      (setf *failed* nil)
      (loop for _t in tests
	 do (funcall (symbol-function _t)))
      (when *failed*
	(format t "~%Failed:~%")
	(let (prev)
	  (dolist (f (reverse *failed*))
	    (if (eq prev (car f))
		(format t " [~a]" (cdr f))
		(format t "~&  ~a [~a]" (car f) (cdr f)))
	    (setf prev (car f))))
	(format t "~%"))
      (format t "~%")
      (values))))
