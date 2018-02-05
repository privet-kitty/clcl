(cl:in-package :cl-user)

(defpackage :dufy
  (:use :common-lisp :alexandria)
  (:export :nearyly=
	   :nearly<=

	   ;; xyz.lisp
	   :gen-spectrum
	   :gen-illum-d-spectrum
	   :spectrum-to-xyz
	   :xyz-to-spectrum
	   :bb-spectrum
	   :optimal-spectrum
	   :flat-spectrum
	   :spectrum-sum

	   :observer
	   :make-observer
	   :observer-cmf-x
	   :observer-cmf-y
	   :observer-cmf-z
	   :observer-cmf
	   :observer-cmf-arr
	   :observer-begin-wl
	   :observer-end-wl
	   :+obs-cie1931+
	   :+obs-cie1964+
	   
	   :xyy-to-xyz
	   :xyz-to-xyy
	   :illuminant
	   :illuminant-x
	   :illuminant-y
	   :illuminant-largex
	   :illuminant-largey
	   :illuminant-largez
	   :illuminant-spectrum
	   :make-illuminant
	   :make-illuminant-by-spd
	   :+illum-a+ :+illum-e+
	   :+illum-c+ :+illum-d50+ :+illum-d65+
	   :calc-cat-matrix
	   :gen-cat-function
	   :gen-cat-function-xyy

	   :cat
	   :make-cat
	   :cat-matrix
	   :cat-inv-matrix
	   :xyz-to-lms
	   :lms-to-xyz
	   :+bradford+
	   :+xyz-scaling+
	   :+von-kries+
	   :+cmccat97+
	   :+cmccat2000+
	   :+cat97s-revised+
	   :+cat02+

	   :rgbspace
	   :+srgb+ :+srgbd50+
	   :+adobe+ :+adobed50+
	   :+ntsc1953+ :+pal/secam+ :+prophoto+
	   :make-rgbspace
	   :copy-rgbspace
	   :rgbspace-linearizer
	   :rgbspace-delinearizer
	   :rgbspace-illuminant
	   :rgbspace-xr
	   :rgbspace-yr
	   :rgbspace-xg
	   :rgbspace-yg
	   :rgbspace-xb
	   :rgbspace-yb
	   :rgbspace-to-xyz-matrix
	   :rgbspace-from-xyz-matrix
	   :gen-linearizer
	   :gen-delinearizer

	   :xyz-to-lab
	   :lab-to-xyz
	   :lstar-to-y
	   :qrgb-to-lab
	   :lab-to-lchab
	   :lchab-to-lab
	   :xyy-to-lab
	   :lab-to-xyy
	   :xyz-to-lchab
	   :xyy-to-lchab
	   :lchab-to-xyz
	   :lchab-to-xyy

	   :xyz-to-luv
	   :luv-to-xyz
	   :luv-to-lchuv
	   :lchuv-to-luv
	   :xyz-to-lchuv
	   :lchuv-to-xyz

	   :delinearize
	   :linearize
	   :nearly=
	   :nearly<=
	   :xyz-to-lrgb
	   :lrgb-to-xyz
	   :rgb-to-lrgb
	   :lrgb-to-rgb
	   :xyz-to-rgb
	   :rgb-to-xyz
	   :rgb-to-qrgb
	   :qrgb-to-rgb
	   :xyz-to-qrgb
	   :qrgb-to-xyz
	   :qrgb-to-hex
	   :hex-to-qrgb
	   :rgb-to-hex
	   :hex-to-rgb
	   :xyz-to-hex
	   :hex-to-xyz
	   :two-pi
	   :subtract-with-mod
	   :circular-lerp

	   :hsv-to-rgb
	   :rgb-to-hsv
	   :hsv-to-qrgb
	   :qrgb-to-hsv
	   :hsv-to-xyz
	   :xyz-to-hsv

	   :hsl-to-rgb
	   :rgb-to-hsl
	   :hsl-to-qrgb
	   :qrgb-to-hsl
	   :hsl-to-xyz
	   :xyz-to-hsl
	   
	   ;; deltae.lisp
	   :deltae
	   :xyz-deltae
	   :qrgb-deltae
	   :deltae94
	   :xyz-deltae94
	   :qrgb-deltae94
	   :deltae00
	   :xyz-deltae00
	   :qrgb-deltae00

	   ;; munsell.lisp
	   :munsell-value-to-y
	   :y-to-munsell-value
	   :qrgb-to-munsell-value
	   :mhvc-out-of-mrd-p
	   :mhvc-to-xyy
	   :mhvc-to-xyz
	   :mhvc-to-xyz-illum-c
	   :mhvc-to-lrgb
	   :mhvc-to-qrgb
	   :mhvc-to-lchab
	   :mhvc-to-munsell
	   :munsell-to-mhvc
	   :munsell-out-of-mrd-p
	   :munsell-to-lchab
	   :munsell-to-xyz
	   :munsell-to-xyy
	   :munsell-to-qrgb
	   :max-chroma
	   :lchab-to-mhvc
	   :lchab-to-munsell
	   :*maximum-chroma*
))
