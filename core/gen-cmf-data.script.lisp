;;; This is a script file which generates fundamental data and saves
;;; them as a .lisp file.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (ql:quickload :dufy/internal/*))

(use-package :dufy/internal)

;;
;; Definitions
;;

(defparameter *dest-path*
  (uiop:merge-pathnames* "cmf-data.lisp" (uiop:current-lisp-file-pathname)))

(defparameter cmf-table-cie1931
  (make-array '(471 3) :element-type 'double-float :initial-element 0d0))
(defparameter cmf-table-cie1964
  (make-array '(471 3) :element-type 'double-float :initial-element 0d0))

(defun fill-color-matching-arr (arr csv-path)
  (with-open-file (in csv-path :direction :input)
    (let ((*read-default-float-format* 'double-float))
      (dotimes (idx 471)
        (read in) ; Skips the first column
        (dotimes (coord 3)
          (setf (aref arr idx coord)
                (coerce (read in) 'double-float)))))))

;;
;; Main
;;

(fill-color-matching-arr cmf-table-cie1931 (uiop:merge-pathnames* "cmf-cie1931.tsv" *dat-dir-path*
                                            ))
(fill-color-matching-arr cmf-table-cie1964 (uiop:merge-pathnames* "cmf-cie1964.tsv" *dat-dir-path*))

(uiop:with-output-file (out *dest-path* :if-exists :supersede)
  (format out ";;; This file is automatically generated by ~A.~%~%"
          (file-namestring (uiop:current-lisp-file-pathname)))
  (format out "~S~%~S~%~%"
          '(uiop:define-package :dufy/core/cmf-data
            (:use :cl)
            (:export #:+cmf-table-cie1931+ #:+cmf-table-cie1964+))
          '(in-package :dufy/core/cmf-data))
  (print-make-array "+CMF-TABLE-CIE1931+" cmf-table-cie1931 out)
  (print-make-array "+CMF-TABLE-CIE1964+" cmf-table-cie1964 out))

(format t "The file is saved at ~A~%" *dest-path*)

#-swank (uiop:quit)
