(in-package :cl-user)

(defpackage dufy-test
  (:use :cl :fiveam :dufy :alexandria))
(in-package :dufy-test)

(def-suite :dufy-suite)
(in-suite :dufy-suite)

(defparameter *xyz-set*
  '((0.6018278793248849d0 0.3103175002768938d0 0.028210681843353954d0)
    (4.846309924502165d-6 5.099078671483812d-6 5.552388656107547d-6)
    (0.9504285453771808d0 1.0000000000000202d0 1.0889003707981277d0)))

(defparameter *xyy-set*
  (mapcar #'(lambda (lst) (multiple-value-list (apply #'xyz-to-xyy lst)))
	  *xyz-set*))

(defparameter *qrgb16-set*
  '((65535 65534 65533) (0 1000 2000) (-1000 6000 70000)))


(defparameter *illum-d55-10*
  (make-illuminant-by-spd (gen-illum-d-spectrum #.(* 5500 (/ 1.43880d0 1.438))) +obs-cie1964+))

(test test-spectrum
  (is (nearly-equal 1d-4
		    '(0.33411d0 0.34877)
		    (list (illuminant-small-x *illum-d55-10*)
			  (illuminant-small-y *illum-d55-10*))))
  (is (nearly-equal 1d-3
		    '(0.95047d0 1d0 1.08883d0)
		    (multiple-value-list
		     (spectrum-to-xyz #'flat-spectrum +illum-d65+))))
  (is (nearly-equal 1d-4
		    '(0.33411 0.34877 1.0d0)
		    (multiple-value-list
		     (multiple-value-call #'xyz-to-xyy
		       (spectrum-to-xyz #'flat-spectrum *illum-d55-10*)))))
  (dolist (xyz *xyz-set*)
    (is (nearly-equal 1d-4
		      xyz
		      (multiple-value-list
		       (spectrum-to-xyz (apply (rcurry #'xyz-to-spectrum *illum-d55-10*)
					       xyz)
					*illum-d55-10*))))))

(test test-xyy
  (dolist (xyz *xyz-set*)
    (is (nearly-equal 1d-4
		      xyz
		      (multiple-value-list
		       (multiple-value-call #'xyy-to-xyz
			 (apply #'xyz-to-xyy xyz)))))))

(test test-cat
  (dolist (xyz *xyz-set*)
    (is (nearly-equal 1d-4
		      xyz
		      (multiple-value-list
		       (multiple-value-call #'lms-to-xyz
			 (apply (rcurry #'xyz-to-lms
					:illuminant *illum-d55-10*
					:cat +cmccat97+)
				xyz)
			 :illuminant *illum-d55-10*
			 :cat +cmccat97+)))))
  (let ((cat-func (gen-cat-function *illum-d55-10* +illum-a+))
	(cat-func-rev (gen-cat-function +illum-a+ *illum-d55-10*)))
    (dolist (xyz *xyz-set*)
      (is (nearly-equal 1d-4
			xyz
			(multiple-value-list
			 (multiple-value-call cat-func-rev
			   (apply cat-func xyz))))))))
			 
		      
(test test-rgb
  (dolist (xyz *xyz-set*)
    (is (nearly-equal 1d-4
		      xyz
		      (multiple-value-list
		       (multiple-value-call #'rgb-to-xyz
			 (apply (rcurry #'xyz-to-rgb +scrgb-nl+) xyz)
			 +scrgb-nl+)))))
  (dolist (rgbspace (list +bg-srgb-16+ +scrgb-nl+ (copy-rgbspace +scrgb-16+ :illuminant +illum-a+ :bit-per-channel 21)))
    (dolist (qrgb *qrgb16-set*)
      (is (equal qrgb
		 (multiple-value-list
		  (multiple-value-call #'xyz-to-qrgb
		    (apply (rcurry #'qrgb-to-xyz rgbspace)
			   qrgb)
		    :rgbspace rgbspace))))))
  (is (equal '(0 5001 65535)
	     (multiple-value-list
	      (hex-to-qrgb (qrgb-to-hex 0 5001 65535 +bg-srgb-16+)
			   +bg-srgb-16+))))
  (dolist (hex '(#x000011112222 #x5678abcdffff))
    (is (= hex
	   (multiple-value-call #'xyz-to-hex
	     (hex-to-xyz hex +bg-srgb-16+)
	     +bg-srgb-16+)
	   hex))
    (is (= hex
	   (multiple-value-call #'rgb-to-hex
	     (hex-to-rgb hex +bg-srgb-16+)
	     +bg-srgb-16+)
	   hex))))
	     
(test test-lab/luv
  (dolist (xyy *xyy-set*)
    (is (nearly-equal 1d-4
		      xyy
		      (multiple-value-list
		       (multiple-value-call #'lchab-to-xyy
			 (apply (rcurry #'xyy-to-lchab *illum-d55-10*)
				xyy)
			 *illum-d55-10*)))))
  (dolist (xyz *xyz-set*)
    (is (nearly-equal 1d-4
		      xyz
		      (multiple-value-list
		       (multiple-value-call #'lchuv-to-xyz
			 (apply (rcurry #'xyz-to-lchuv *illum-d55-10*)
				xyz)
			 *illum-d55-10*))))))

(test test-hsv/hsl
  (loop for xyz-to-foo in '(xyz-to-hsv xyz-to-hsl)
     for foo-to-xyz in '(hsv-to-xyz hsl-to-xyz) do
       (dolist (xyz *xyz-set*)
	 (is (nearly-equal 1d-4
			   xyz
			   (multiple-value-list
			    (multiple-value-call foo-to-xyz
			      (apply (rcurry xyz-to-foo +bg-srgb-16+)
				     xyz)
			      +bg-srgb-16+))))))
  (loop for qrgb-to-foo in '(qrgb-to-hsv qrgb-to-hsl)
     for foo-to-qrgb in '(hsv-to-qrgb hsl-to-qrgb) do
       (dolist (rgbspace (list +bg-srgb-16+ +prophoto-16+))
	 (dolist (qrgb *qrgb16-set*)
	   (is (equal qrgb
		      (multiple-value-list
		       (multiple-value-call foo-to-qrgb
			 (apply (rcurry qrgb-to-foo rgbspace)
				qrgb)
			 :rgbspace rgbspace))))))))

(test test-deltae
  (let ((*read-default-float-format* 'double-float))
    (is (nearly= 1d-3
		 (deltae00 63.0109 -31.0961 -5.8663
			   62.8187 -29.7946 -4.0864)
		 1.2630))))

(test test-munsell
  (dolist (xyz *xyz-set*)
    (is (nearly-equal 1d-4
		      xyz
		      (multiple-value-list
		       (multiple-value-call #'munsell-to-xyz
			 (nth-value 0 (apply (rcurry #'xyz-to-munsell :digits 6)
					     xyz))))))))


;; (let ((*read-default-float-format* 'double-float))
;;   (test test-core
;;     (is (equal '(50 100 150)
;; 	       (apply #'dufy:xyz-to-qrgb (dufy:qrgb-to-xyz 50 100 150))))
;;     (is (nearly= 1d-3
;; 		 (deltae00 63.0109 -31.0961 -5.8663
;; 			   62.8187 -29.7946 -4.0864)
;; 		 1.2630))
;;     (is (equal '(200 2000 3000)
;; 	       (apply (alexandria:rcurry #'dufy:xyz-to-qrgb :rgbspace dufy:+bg-srgb-12+)
;; 		      (dufy:qrgb-to-xyz 200 2000 3000 dufy:+bg-srgb-12+))))
;;     (is (equal '(200 2000 3000)
;; 	       (apply (alexandria:rcurry #'dufy:xyz-to-qrgb :rgbspace dufy:+scrgb-nl+)
;; 		      (dufy:qrgb-to-xyz 200 2000 3000 dufy:+scrgb-nl+))))
;;     (is (= 3363638200
;; 	   (apply (alexandria:rcurry #'dufy:xyz-to-hex :rgbspace dufy:+bg-srgb-12+)
;; 		  (dufy:hex-to-xyz 3363638200 dufy:+bg-srgb-12+))))
;;     (is (= 3363638200
;; 	   (apply (alexandria:rcurry #'dufy:xyz-to-hex :rgbspace dufy:+scrgb-nl+)
;; 		  (dufy:hex-to-xyz 3363638200 dufy:+scrgb-nl+)))))
  
;;   (test test-hsv
;;     (dolist (h '(20 70 140 200 260 320))
;;       (is (nearly-equal 1d-4
;; 			(list h 0.3d0 0.4d0)
;; 			(apply (rcurry #'xyz-to-hsv :rgbspace +adobe+)
;; 			       (hsv-to-xyz h 0.3d0 0.4d0 +adobe+)))))
;;     (is (equal '(20 30 100)
;; 	       (apply (rcurry #'hsv-to-qrgb +adobe-16+)
;; 		      (qrgb-to-hsv 20 30 100 +adobe-16+))))
;;     (is (equal '(0 0 0)
;; 	       (apply (rcurry #'hsv-to-qrgb +adobe-16+)
;; 		      (qrgb-to-hsv 0 0 0 +adobe-16+)))))
  
;;   (test test-hsl
;;     (dolist (h '(20 70 140 200 260 320))
;;       (is (nearly-equal 1d-4
;; 			(list h 0.3d0 0.4d0)
;; 			(apply (rcurry #'xyz-to-hsl :rgbspace +prophoto+)
;; 			       (hsl-to-xyz h 0.3d0 0.4d0 +prophoto+)))))
;;     (is (equal '(20 30 100)
;; 	       (apply (rcurry #'hsl-to-qrgb +prophoto+)
;; 		      (qrgb-to-hsl 20 30 100 +prophoto+))))
;;     (is (equal '(0 0 0)
;; 	       (apply (rcurry #'hsl-to-qrgb +adobe-16+)
;; 		      (qrgb-to-hsl 0 0 0 +adobe-16+))))))
