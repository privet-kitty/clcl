(in-package :dufy)

;; define delta-E functions for L*a*b*, xyz and qrgb
(defmacro defdeltae (name args &body body)
  "Only &key arguments are allowed in sub-args. The following symbols
cannot be used in ARGS: x1 y1 z1 x2 y2 z2 r1 g1 b1 r2 g2 b2"
  (labels ((extract (lst) ; extract sub-args
	     (reduce #'append
		     (mapcar #'(lambda (pair)
				 (list (intern (symbol-name (first pair)) :keyword)
				       (first pair)))
			     lst))))
    (let* ((main-args (subseq args 0 6))
	   (sub-args-with-key (subseq args 6))
	   (sub-args (cdr sub-args-with-key))
	   (qrgb-name (intern (format nil "QRGB-~A" name) :dufy))
	   (xyz-name (intern (format nil "XYZ-~A" name) :dufy)))
      `(progn
	 (defun ,name (,@main-args ,@sub-args-with-key)
	   ,@body)
	 (defun ,xyz-name (x1 y1 z1 x2 y2 z2 &key ,@sub-args (illuminant +illum-d65+))
	   (multiple-value-call #',name
	     (xyz-to-lab x1 y1 z1 illuminant)
	     (xyz-to-lab x2 y2 z2 illuminant)
	     ,@(extract sub-args)))
	 (defun ,qrgb-name (r1 g1 b1 r2 g2 b2 &key ,@sub-args (rgbspace +srgb+))
	   (multiple-value-call #',xyz-name
	     (qrgb-to-xyz r1 g1 b1 rgbspace)
	     (qrgb-to-xyz r2 g2 b2 rgbspace)
	     ,@(extract sub-args)
	     :illuminant (rgbspace-illuminant rgbspace)))))))


;; CIE76
(defdeltae deltae (l1 a1 b1 l2 a2 b2)
  (declare (optimize (speed 3) (safety 1)))
  (let ((l1 (float l1 1d0))
	(a1 (float a1 1d0))
	(b1 (float b1 1d0))
	(l2 (float l2 1d0))
	(a2 (float a2 1d0))
	(b2 (float b2 1d0)))
    (let ((deltal (- l1 l2))
	  (deltaa (- a1 a2))
	  (deltab (- b1 b2)))
      (sqrt (+ (* deltal deltal)
	       (* deltaa deltaa)
	       (* deltab deltab))))))

;; (defun xyz-deltae (x1 y1 z1 x2 y2 z2 &key (illuminant +illum-d65+))
;;   (destructuring-bind (l1 a1 b1) (xyz-to-lab x1 y1 z1 illuminant)
;;     (destructuring-bind (l2 a2 b2) (xyz-to-lab x2 y2 z2 illuminant)
;;       (deltae l1 a1 b1 l2 a2 b2))))

;; (defun qrgb-deltae (r1 g1 b1 r2 g2 b2 &key (rgbspace +srgb+))
;;   (destructuring-bind (x1 y1 z1) (qrgb-to-xyz r1 g1 b1 rgbspace)
;;     (destructuring-bind (x2 y2 z2) (qrgb-to-xyz r2 g2 b2 rgbspace)
;;       (xyz-deltae x1 y1 z1 x2 y2 z2 :illuminant (rgbspace-illuminant rgbspace)))))



;; CIE94
(defdeltae deltae94 (l1 a1 b1 l2 a2 b2 &key (application :graphic-arts))
  "APPLICATION must be :graphic-arts or :textiles"
  (declare (optimize (speed 3) (safety 1)))
  (let ((l1 (float l1 1d0))
	(a1 (float a1 1d0))
	(b1 (float b1 1d0))
	(l2 (float l2 1d0))
	(a2 (float a2 1d0))
	(b2 (float b2 1d0)))
    (let ((c1 (sqrt (+ (* a1 a1) (* b1 b1))))
	  (c2 (sqrt (+ (* a2 a2) (* b2 b2)))))
      (let* ((delta-l (- l1 l2))
	     (delta-c (- c1 c2))
	     (delta-a (- a1 a2))
	     (delta-b (- b1 b2))
	     (delta-h (sqrt (the (double-float 0d0)
				 (+ (* delta-a delta-a)
				    (* delta-b delta-b)
				    (- (* delta-c delta-c)))))))
	(multiple-value-bind (kL k1 k2)
	    (case application
	      (:graphic-arts (values 1d0 0.045d0 0.015d0))
	      (:textiles (values 2d0 0.048d0 0.014d0))
	      (otherwise (error "Unknown APPLICATION: ~A" application)))
	  (let ((sc (+ 1d0 (* k1 c1)))
		(sh (+ 1d0 (* k2 c1))))
	    (let ((term1 (/ delta-l kL))
		  (term2 (/ delta-c sc))
		  (term3 (/ delta-h sh)))
	      (sqrt (+ (* term1 term1)
		       (* term2 term2)
		       (* term3 term3))))))))))


;; (defun xyz-deltae94 (x1 y1 z1 x2 y2 z2 &key (illuminant +illum-d65+) (application :graphic-arts))
;;   (destructuring-bind (l1 a1 b1) (xyz-to-lab x1 y1 z1 illuminant)
;;     (destructuring-bind (l2 a2 b2) (xyz-to-lab x2 y2 z2 illuminant)
;;       (deltae94 l1 a1 b1 l2 a2 b2 :application application))))

;; (defun qrgb-deltae94 (r1 g1 b1 r2 g2 b2 &key (rgbspace +srgb+) (application :graphic-arts))
;;   (destructuring-bind (x1 y1 z1) (qrgb-to-xyz r1 g1 b1 rgbspace)
;;     (destructuring-bind (x2 y2 z2) (qrgb-to-xyz r2 g2 b2 rgbspace)
;;       (xyz-deltae94 x1 y1 z1 x2 y2 z2
;; 		    :illuminant (rgbspace-illuminant rgbspace)
;; 		    :application application))))


;; CIEDE2000
(defdeltae deltae00 (l1 a1 b1 l2 a2 b2)
  (declare (optimize (speed 3) (safety 1)))
  (let ((l1 (float l1 1d0))
	(a1 (float a1 1d0))
	(b1 (float b1 1d0))
	(l2 (float l2 1d0))
	(a2 (float a2 1d0))
	(b2 (float b2 1d0)))
    (let ((c1 (sqrt (+ (* a1 a1) (* b1 b1))))
	  (c2 (sqrt (+ (* a2 a2) (* b2 b2)))))
      (let* ((deltaLprime (- l2 l1))
	     (Lavg (* 0.5d0 (+ l1 l2)))
	     (Cavg (* 0.5d0 (+ c1 c2)))
	     (Cavg7 (the (double-float 0d0) (expt Cavg 7)))
	     (const1 (* 0.5d0 (- 1d0 (sqrt (/ Cavg7 (+ Cavg7 #.(expt 25 7)))))))
	     (aprime1 (+ a1 (* a1 const1)))
	     (aprime2 (+ a2 (* a2 const1)))
	     (Cprime1 (sqrt (+ (* aprime1 aprime1) (* b1 b1))))
	     (Cprime2 (sqrt (+ (* aprime2 aprime2) (* b2 b2))))
	     (Cavgprime (* 0.5d0 (+ Cprime1 Cprime2)))
	     (deltaCprime (- Cprime2 Cprime1))
	     (hprime1 (if (and (= b1 0) (= aprime1 0))
			  0d0
			  (mod (* (atan b1 aprime1) #.(/ 180d0 PI)) 360d0)))
	     (hprime2 (if (and (= b2 0) (= aprime2 0))
			  0d0
			  (mod (* (atan b2 aprime2) #.(/ 180d0 PI)) 360d0)))
	     (deltahprime (cond ((or (= Cprime1 0d0) (= Cprime2 0d0))
				 0d0)
				((<= (abs (- hprime1 hprime2)) 180d0)
				 (- hprime2 hprime1))
				((<= hprime2 hprime1)
				 (+ (- hprime2 hprime1) 360d0))
				(t
				 (- hprime2 hprime1 360))))
	     (deltalargeHprime (* 2d0
				  (sqrt (* Cprime1 Cprime2))
				  (sin (* deltahprime #.(* 0.5d0 PI 1/180)))))
	     (Havgprime (cond ((or (= Cprime1 0) (= Cprime2 0))
			       (+ hprime1 hprime2))
			      ((<= (abs (- hprime1 hprime2)) 180d0)
			       (* 0.5d0 (+ hprime1 hprime2)))
			      ((< (+ hprime1 hprime2) 360d0)
			       (* 0.5d0 (+ hprime1 hprime2 360d0)))
			      (t
			       (* 0.5d0 (+ hprime1 hprime2 -360d0)))))
	     (varT (+ 1d0
		      (* -0.17d0 (cos (* (- Havgprime 30) #.(/ PI 180d0))))
		      (* 0.24d0 (cos (* 2d0 Havgprime #.(/ PI 180d0))))
		      (* 0.32d0 (cos (* (+ (* 3d0 Havgprime) 6d0) #.(/ PI 180))))
		      (* -0.20d0 (cos (* (- (* 4d0 Havgprime) 63d0) #.(/ PI 180))))))
	     (Lavg-50 (- Lavg 50d0))
	     (tmp (* Lavg-50 Lavg-50))
	     (varSL (+ 1d0 (/ (* 0.015d0 tmp)
			      (sqrt (+ 20d0 tmp)))))
	     (varSC (+ 1d0 (* 0.045d0 Cavgprime)))
	     (varSH (+ 1d0 (* 0.015d0 Cavgprime varT)))
	     (Cavgprime7 (the (double-float 0d0) (expt Cavgprime 7)))
	     (varRT  (* -2d0
			(sqrt (/ Cavgprime7 (+ Cavgprime7 #.(expt 25 7))))
			(sin (* 60d0
				(exp (- (expt (* (- Havgprime 275d0) 1/25) 2)))
				#.(/ PI 180))))))
	(sqrt (the (double-float 0d0)
		   (+ (/ (* deltaLprime deltaLprime)
			 (* varSL varSL))
		      (/ (* deltaCprime deltaCPrime)
			 (* varSC varSC))
		      (/ (* deltalargeHprime deltalargeHprime)
			 (* varSH varSH))
		      (* varRT (/ deltaCprime varSC) (/ deltalargeHprime varSH)))))))))

;; (defun xyz-deltae00 (x1 y1 z1 x2 y2 z2 &key (illuminant +illum-d65+))
;;   (destructuring-bind (l1 a1 b1) (xyz-to-lab x1 y1 z1 illuminant)
;;     (destructuring-bind (l2 a2 b2) (xyz-to-lab x2 y2 z2 illuminant)
;;       (deltae00 l1 a1 b1 l2 a2 b2))))

;; (defun qrgb-deltae00 (r1 g1 b1 r2 g2 b2 &key (rgbspace +srgb+))
;;   (destructuring-bind (x1 y1 z1) (qrgb-to-xyz r1 g1 b1 rgbspace)
;;     (destructuring-bind (x2 y2 z2) (qrgb-to-xyz r2 g2 b2 rgbspace)
;;       (xyz-deltae00 x1 y1 z1 x2 y2 z2
;; 		    :illuminant (rgbspace-illuminant rgbspace)))))

(defun bench-deltae00 (&optional (num 1000000))
  (time (dotimes (x num)
	  (qrgb-deltae00 (random 65536) (random 65536) (random 65536)
			 (random 65536) (random 65536) (random 65536)
			 :rgbspace +bg-srgb-16+))))
