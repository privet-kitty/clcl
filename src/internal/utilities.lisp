;;;
;;; General definitions, functions and macros
;;;

(in-package :dufy-internal)

;;
;; For preprocessing of data file
;;

(defparameter *dat-dir-path* (asdf:component-pathname (asdf:find-component (asdf:find-system :dufy) :dat)))

(defun array-to-list (array)
  "array->list coercion"
  (let* ((dimensions (array-dimensions array))
         (indices (make-list (length dimensions) :initial-element 0)))
    (labels ((traverse (dimensions-rest indices-rest)
               (loop for idx of-type fixnum below (car dimensions-rest)
                  do (setf (car indices-rest) idx)
                  collect (if (null (cdr dimensions-rest))
                              (apply #'aref array indices)
                              (traverse (cdr dimensions-rest)
                                       (cdr indices-rest))))))
      (traverse dimensions indices))))

(defun print-make-array (var-name array &optional (stream t) (declaration t) (load-time-value nil))
  "Prints a form like (defparameter VAR-NAME (make-array ...))."
  (labels ((wrap-with-load-time-value (form)
             `(load-time-value ,form t)))
    (let ((typ (array-element-type array))
          (dims (array-dimensions array)))
      (when declaration
        (format stream "~S~%"
                `(declaim (type (simple-array ,typ ,dims)
                                ,(intern (string-upcase var-name))))))
      (format stream "(DEFPARAMETER ~A~% ~S)~%"
              (string-upcase var-name)
              (funcall (if load-time-value
                           #'wrap-with-load-time-value
                           #'identity)
                       `(make-array ',dims
                                    :element-type ',typ
                                    :initial-contents ',(array-to-list array)))))))

;;
;; General constants and macros
;;

(define-constant TWO-PI (float (+ PI PI) 1d0))
(define-constant +TWO-PI/360+ (/ TWO-PI 360))
(define-constant +360/TWO-PI+ (/ 360 TWO-PI))

(defmacro dotimes-unroll ((var count &optional result) &body body)
  `(block nil
     ,@(loop for i from 0 below count
             collect `(let ((,var ,i)) ,@body))
     ,result))

(defmacro with-ensuring-type (type vars &body body)
  "Ensures that the type of variables are TYPE."
  (labels ((expand (var-lst)
	     (if (null var-lst)
		 nil
		 (cons `(,(car var-lst) (coerce ,(car var-lst) ',type))
		       (expand (cdr var-lst))))))
    `(let ,(expand vars)
       (declare (type ,type ,@vars))
       ,@body)))

;;
;; For benchmark
;;

(defmacro internal-real-time (&body body)
  "For development. Returns elapsed (internal real) time."
  (let ((start (gensym)))
    `(let ((,start (get-internal-real-time)))
       ,@body
       (/ (float (- (get-internal-real-time) ,start) 1d0)
	  internal-time-units-per-second))))

(defmacro time-after-gc (&body body)
  "TIME macro after GC"
  `(progn
     #+sbcl(sb-ext:gc :full t)
     #+ccl(ccl:gc)
     (time ,@body)))

(defmacro internal-real-time-after-gc (&body body)
  "INTERNAL-REAL-TIME macro after GC"
  `(progn
     #+sbcl(sb-ext:gc :full t)
     #+ccl(ccl:gc)
     (internal-real-time ,@body)))

(defmacro time-median (num &body body)
  "Repeats BODY NUM times and returns the median of elapsed (internal
real) times."
  (let ((i (gensym)))
    `(alexandria:median
      (loop for ,i below ,num
            collect (internal-real-time-after-gc ,@body)))))

#+sbcl
(defmacro with-profiling (&body body)
  `(unwind-protect
        (progn (sb-profile:profile "DUFY")
               ,@body
               (sb-profile:report :print-no-call-list nil))
     (sb-profile:unprofile "DUFY")))

;;
;; Approximate comparison operators
;; (used mainly for test)
;;

(defun nearly= (threshold number &rest more-numbers)
  "THRESHOLD means acceptable absolute error."
  (if (null more-numbers)
      t
      (and (<= (abs (- number (car (the cons more-numbers)))) threshold)
	   (apply #'nearly= threshold more-numbers))))

(defun nearly-equal (threshold lst1 &rest lsts)
  "THRESHOLD means acceptable absolute error."
  (if (null lst1)
      t
      (and (apply #'nearly= threshold
                  (car lst1)
                  (mapcar #'car lsts))
	   (apply #'nearly-equal threshold
                  (cdr lst1)
                  (mapcar #'cdr lsts)))))

(defun nearly<= (threshold number &rest more-numbers)
  (if (null more-numbers)
      t
      (and (<= (- number (car (the cons more-numbers))) threshold)
	   (apply #'nearly<= threshold more-numbers))))

;;
;; Some arithmetic in a circle group
;;

(declaim (inline subtract-with-mod))
(defun subtract-with-mod (x y &optional (divisor TWO-PI))
  "Returns (X - Y) mod DIVISOR."
  (mod (- x y) divisor))

(declaim (inline circular-nearer))
(defun circular-nearer (theta1 x theta2 &optional (perimeter TWO-PI))
  "Compares the counterclockwise distances between THETA1 and X and
between X and THETA2, and returns THETA1 or THETA2 whichever is
nearer."
  (if (<= (subtract-with-mod x theta1 perimeter)
	  (subtract-with-mod theta2 x perimeter))
      theta1
      theta2))

(declaim (inline circular-clamp))
(defun circular-clamp (number min max &optional (perimeter TWO-PI))
  "A clamp function in a circle group. If NUMBER is not in
the (counterclockwise) closed interval [MIN, MAX], CIRCULAR-CLAMP
returns MIN or MAX whichever is nearer to NUMBER."
  (let ((number$ (mod number perimeter))
	(min$ (mod min perimeter))
	(max$ (mod max perimeter)))
    (if (<= min$ max$)
	(if (<= min$ number$ max$)
	    number$ ; [min, number, max]
	    (circular-nearer max$ number$ min$))   ; [min, max, number] or [number, min, max]
	(if (or (<= number$ max$)  (<= min$ number$))
	    number$ ;[number, max, min] or [max, min, number]
	    (circular-nearer max$ number$ min$))))) ; [max, number, min]

(declaim (inline circular-lerp))
(defun circular-lerp (coef theta1 theta2 &optional (perimeter TWO-PI))
  "Counterclockwise linear interpolation from THETA1 to THETA2 in a
circle group. It is guaranteed that the return value doesn't exceed
the given interval from THETA1 to THETA2 if COEF is in [0, 1]. It is,
however, slower than CIRCULAR-LERP-LOOSE."
  (let ((dtheta (subtract-with-mod theta2 theta1 perimeter)))
    (circular-clamp (+ theta1 (* dtheta coef))
		    theta1
		    theta2
		    perimeter)))

(declaim (inline circular-lerp-loose))
(defun circular-lerp-loose (coef theta1 theta2 &optional (perimeter TWO-PI))
  "Counterclockwise linear interpolation from THETA1 to THETA2 in a
circle group. There is a possibility that the return value slightly
exceeds the interval [THETA1, THETA2] due to floating-point error. If
that is incovenient, you should use CIRCULAR-LERP instead."
  (let ((dtheta (subtract-with-mod theta2 theta1 perimeter)))
    (mod (+ theta1 (* dtheta coef)) perimeter)))

(declaim (inline circular-member))
(defun circular-member (x theta1 theta2 &optional (perimeter TWO-PI))
  "Returns true if X is within the counterclockwise closed interval [THETA1,
THETA2] in a circle group."
  (let ((x-m (mod x perimeter))
	(theta1-m (mod theta1 perimeter))
	(theta2-m (mod theta2 perimeter)))
    (if (<= theta1-m theta2-m)
	(and (<= theta1-m x-m)
	     (<= x-m theta2))
	(or (<= theta1-m x-m)
	    (<= x-m theta2)))))


;;
;; Miscellaneous arithmetic
;;

(defmacro fast-expt (base power)
  "Exponentiation by squaring. POWER must be a literal of
type (integer 1)."
  (assert (constantp power))
  (check-type power (integer 1))
  (labels ((round-off-to-power-of-2 (num)
             (let* ((approx (log num 2))
                    (flo (expt 2 (floor approx)))
                    (ceil (expt 2 (ceiling approx))))
               (if (<= ceil num) ceil flo)))
           (decompose-to-sum-of-powers-of-2 (num result)
             (if (zerop num)
                 result
                 (let ((k (round-off-to-power-of-2 num)))
                   (decompose-to-sum-of-powers-of-2 (- num k) (cons k result))))))
    (let* ((parts (decompose-to-sum-of-powers-of-2 power nil))
           (m (apply #'max (cons 1 parts)))
           (vars (apply #'vector
                        (loop for i from 0 to (round (log m 2))
                              collect (gensym (format nil "POW~A-" (expt 2 i)))))))
      `(let* ((,(aref vars 0) ,base) 
              ,@(loop for i from 1
                      for num = (expt 2 i)
                      until (> num m)
                      collect `(,(aref vars i) (* ,(aref vars (- i 1))
                                                  ,(aref vars (- i 1))))))
         ,(if (= 1 (length parts))
              (last-elt vars)
              `(* ,@(loop for num in parts
                          collect (aref vars (round (log num 2))))))))))

(declaim (inline square))
(defun square (x) (* x x))
