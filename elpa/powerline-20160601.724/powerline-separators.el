;;; powerline-separators.el --- Separators for Powerline

;; Copyright (C) 2012-2013 Donald Ephraim Curtis
;; Copyright (C) 2013 Jason Milkins
;; Copyright (C) 2012 Nicolas Rougier

;; Author: Donald Ephraim Curtis <dcurtis@milkbox.net>
;; URL: http://github.com/milkypostman/powerline/
;; Version: 2.0
;; Keywords: mode-line

;;; Commentary:
;;
;; Separators for Powerline.
;; Included separators: alternate, arrow, arrow-fade, bar, box, brace, butt,
;; chamfer, contour, curve, rounded, roundstub, slant, wave, zigzag, and nil.
;;

;;; Code:

(require 'cl-lib)
(require 'color)

(defun pl/interpolate (color1 color2)
  "Interpolate between COLOR1 and COLOR2.

COLOR1 and COLOR2 must be supplied as hex strings with a leading #."
  (let* ((c1 (color-name-to-rgb color1))
         (c2 (color-name-to-rgb color2))
         (red (/ (+ (nth 0 c1) (nth 0 c2)) 2))
         (green (/ (+ (nth 1 c1) (nth 1 c2)) 2))
         (blue (/ (+ (nth 2 c1) (nth 2 c2)) 2)))
    (color-rgb-to-hex red green blue)))

(defun pl/hex-color (color)
  "Get the hexadecimal value of COLOR."
  (when color
    (apply 'color-rgb-to-hex (color-name-to-rgb color))))

(defun pl/pattern (lst)
  "Turn LST into an infinite pattern."
  (when lst
    (let ((pattern (cl-copy-list lst)))
      (setcdr (last pattern) pattern))))

(defun pl/pattern-to-string (pattern)
  "Convert a PATTERN into a string that can be used in an XPM."
  (concat "\"" (mapconcat 'number-to-string pattern "") "\","))

(defun pl/reverse-pattern (pattern)
  "Reverse each line in PATTERN."
  (mapcar 'reverse pattern))

(defun pl/row-pattern (fill total &optional fade)
  "Make a list that has FILL 0s out of TOTAL 1s with FADE 2s to the right of the fill."
  (unless fade
    (setq fade 0))
  (let ((fill (min fill total))
        (fade (min fade (max (- total fill) 0))))
    (append (make-list fill 0)
            (make-list fade 2)
            (make-list (- total fill fade) 1))))

(defun pl/pattern-bindings-body (patterns height-exp pattern-height-sym
					  second-pattern-height-sym)
  "Create let-var bindings and a function body from PATTERNS.
The `car' and `cdr' parts of the result can be passed to the
function `pl/wrap-defun' as its `let-vars' and `body' arguments,
respectively.  HEIGHT-EXP is an expression calculating the image
height and it should contain a free variable `height'.
PATTERN-HEIGHT-SYM and SECOND-PATTERN-HEIGHT-SYM are symbols used
for let-var binding variables."
  (let* ((pattern (pl/pattern (mapcar 'pl/pattern-to-string (car patterns))))
         (header (mapcar 'pl/pattern-to-string (nth 1 patterns)))
         (footer (mapcar 'pl/pattern-to-string (nth 2 patterns)))
         (second-pattern (pl/pattern (mapcar 'pl/pattern-to-string (nth 3 patterns))))
         (center (mapcar 'pl/pattern-to-string (nth 4 patterns)))
         (reserve (+ (length header) (length footer) (length center))))
    (when pattern
      (cons `((,pattern-height-sym (max (- ,height-exp ,reserve) 0))
	      (,second-pattern-height-sym (/ ,pattern-height-sym 2))
	      (,pattern-height-sym ,(if second-pattern `(ceiling ,pattern-height-sym 2) `,pattern-height-sym)))
	    (list (when header `(mapconcat 'identity ',header ""))
		  `(mapconcat 'identity
			      (cl-subseq ',pattern 0 ,pattern-height-sym) "")
		  (when center `(mapconcat 'identity ',center ""))
		  (when second-pattern
		    `(mapconcat 'identity
				(cl-subseq ',second-pattern
					   0 ,second-pattern-height-sym) ""))
		  (when footer `(mapconcat 'identity ',footer "")))))))

(defun pl/pattern-defun (name dir width &rest patterns)
  "Create a powerline function of NAME in DIR with WIDTH for PATTERNS.

PATTERNS is of the form (PATTERN HEADER FOOTER SECOND-PATTERN CENTER
PATTERN-2X HEADER-2X FOOTER-2X SECOND-PATTERN-2X CENTER-2X).
PATTERN is required, all other components are optional.
The first 5 components are for the standard resolution image.
The remaining ones are for the high resolution image where both
width and height are doubled.  If PATTERN-2X is nil or not given,
then the remaining components are ignored and the standard
resolution image with magnification and interpolation will be
used in high resolution environments

All generated functions generate the form:
HEADER
PATTERN ...
CENTER
SECOND-PATTERN ...
FOOTER

PATTERN and SECOND-PATTERN repeat infinitely to fill the space needed to generate a full height XPM.

PATTERN, HEADER, FOOTER, SECOND-PATTERN, CENTER are of the form ((COLOR ...) (COLOR ...) ...).

COLOR can be one of 0, 1, or 2, where 0 is the source color, 1 is the
destination color, and 2 is the interpolated color between 0 and 1."
  (when (eq dir 'right)
    (setq patterns (mapcar 'pl/reverse-pattern patterns)))
  (let ((bindings-body (pl/pattern-bindings-body patterns
						 'height
						 'pattern-height
						 'second-pattern-height))
	(bindings-body-2x (pl/pattern-bindings-body (nthcdr 5 patterns)
						    '(* height 2)
						    'pattern-height-2x
						    'second-pattern-height-2x)))
    (pl/wrap-defun name dir width
		   (append (car bindings-body) (car bindings-body-2x))
		   (cdr bindings-body) (cdr bindings-body-2x))))

(defun pl/background-color (face)
  (face-attribute face
                  (if (face-attribute face :inverse-video nil 'default)
                      :foreground
                    :background)
                  nil
                  'default))

(defun pl/wrap-defun (name dir width let-vars body &optional body-2x)
  "Generate a powerline function of NAME in DIR with WIDTH using LET-VARS and BODY."
  (let* ((src-face (if (eq dir 'left) 'face1 'face2))
         (dst-face (if (eq dir 'left) 'face2 'face1)))
    `(defun ,(intern (format "powerline-%s-%s" name (symbol-name dir)))
       (face1 face2 &optional height)
       (when window-system
         (unless height (setq height (pl/separator-height)))
         (let* ,(append `((color1 (when ,src-face
                                    (pl/hex-color (pl/background-color ,src-face))))
                          (color2 (when ,dst-face
                                    (pl/hex-color (pl/background-color ,dst-face))))
                          (colori (when (and color1 color2) (pl/interpolate color1 color2)))
                          (color1 (or color1 "None"))
                          (color2 (or color2 "None"))
                          (colori (or colori "None")))
                        let-vars)
           (apply 'create-image
		  ,(append `(concat (format "/* XPM */ static char * %s_%s[] = { \"%s %s 3 1\", \"0 c %s\", \"1 c %s\", \"2 c %s\","
					    ,(replace-regexp-in-string "-" "_" name)
					    (symbol-name ',dir)
					    ,width
					    height
					    color1
					    color2
					    colori))
			   body
			   '("};"))
		  'xpm t
		  :ascent 'center
		  :face (when (and face1 face2)
			  ,dst-face)
		  ,(and body-2x
			`(and (featurep 'mac)
			      (list :data-2x
				    ,(append `(concat (format "/* XPM */ static char * %s_%s_2x[] = { \"%s %s 3 1\", \"0 c %s\", \"1 c %s\", \"2 c %s\","
							      ,(replace-regexp-in-string "-" "_" name)
							      (symbol-name ',dir)
							      (* ,width 2)
							      (* height 2)
							      color1
							      color2
							      colori))
					     body-2x
					     '("};")))))))))))

(defmacro pl/alternate (dir)
  "Generate an alternating pattern XPM function for DIR."
  (pl/pattern-defun "alternate" dir 4
                    '((2 2 1 1)
                      (0 0 2 2))
		    nil nil nil nil
		    ;; 2x
		    '((2 2 2 2 1 1 1 1)
		      (2 2 2 2 1 1 1 1)
		      (0 0 0 0 2 2 2 2)
		      (0 0 0 0 2 2 2 2))))

(defmacro pl/arrow (dir)
  "Generate an arrow XPM function for DIR."
  (let ((row-modifier (if (eq dir 'left) 'identity 'reverse)))
    (pl/wrap-defun "arrow" dir 'middle-width
                   '((width (1- (/ height 2)))
                     (middle-width (1- (ceiling height 2))))
                   `((cl-loop for i from 0 to width
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern i middle-width))))
                     (when (cl-oddp height)
                       (pl/pattern-to-string (make-list middle-width 0)))
                     (cl-loop for i from width downto 0
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern i middle-width)))))
		   `((when (cl-evenp height)
                       (pl/pattern-to-string (make-list (* middle-width 2) 1)))
		     (cl-loop for i from 0 to (* middle-width 2)
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern i (* middle-width 2)))))
                     (cl-loop for i from (* middle-width 2) downto 0
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern i (* middle-width 2)))))
		     (when (cl-evenp height)
                       (pl/pattern-to-string (make-list (* middle-width 2) 1)))))))

(defmacro pl/arrow-fade (dir)
  "Generate an arrow-fade XPM function for DIR."
  (let* ((row-modifier (if (eq dir 'left) 'identity 'reverse)))
    (pl/wrap-defun "arrow-fade" dir 'middle-width
                   '((width (1- (/ height 2)))
                     (middle-width (1+ (ceiling height 2))))
                   `((cl-loop for i from 0 to width
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern i middle-width 2))))
                     (when (cl-oddp height)
                       (pl/pattern-to-string (,row-modifier (pl/row-pattern (1+ width) middle-width 2))))
                     (cl-loop for i from width downto 0
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern i middle-width 2)))))
		   `((when (cl-evenp height)
                       (pl/pattern-to-string (,row-modifier (pl/row-pattern 0 (* middle-width 2) (* 2 2)))))
		     (cl-loop for i from 0 to (* (- middle-width 2) 2)
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern i (* middle-width 2) (* 2 2)))))
                     (cl-loop for i from (* (- middle-width 2) 2) downto 0
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern i (* middle-width 2) (* 2 2)))))
		     (when (cl-evenp height)
                       (pl/pattern-to-string (,row-modifier (pl/row-pattern 0 (* middle-width 2) (* 2 2)))))))))

(defmacro pl/bar (dir)
  "Generate a bar XPM function for DIR."
  (pl/pattern-defun "bar" dir 2
                    '((2 2))))

(defmacro pl/box (dir)
  "Generate a box XPM function for DIR."
  (pl/pattern-defun "box" dir 2
                    '((0 0)
                      (0 0)
                      (1 1)
                      (1 1))
		    nil nil nil nil
		    ;; 2x
		    '((0 0 0 0)
		      (0 0 0 0)
		      (0 0 0 0)
		      (0 0 0 0)
		      (1 1 1 1)
		      (1 1 1 1)
		      (1 1 1 1)
		      (1 1 1 1))))

(defmacro pl/brace (dir)
  "Generate a brace XPM function for DIR."
  (pl/pattern-defun "brace" dir 4
                    '((0 1 1 1))
                    '((1 1 1 1)
                      (2 1 1 1))
                    '((2 1 1 1)
                      (1 1 1 1))
                    '((0 1 1 1))
                    '((0 2 1 1)
                      (0 2 1 1)
                      (0 0 2 1)
                      (0 0 0 0)
                      (0 0 2 1)
                      (0 2 1 1)
                      (0 2 1 1))
		    ;; 2x
		    '((0 0 1 1 1 1 1 1))
		    '((1 1 1 1 1 1 1 1)
		      (1 1 1 1 1 1 1 1)
		      (2 1 1 1 1 1 1 1)
		      (0 2 1 1 1 1 1 1))
		    '((0 2 1 1 1 1 1 1)
		      (2 1 1 1 1 1 1 1)
		      (1 1 1 1 1 1 1 1)
		      (1 1 1 1 1 1 1 1))
		    '((0 0 1 1 1 1 1 1))
		    '((0 0 2 1 1 1 1 1)
		      (0 0 0 1 1 1 1 1)
		      (0 0 0 2 1 1 1 1)
		      (0 0 0 0 1 1 1 1)
		      (0 0 0 0 2 1 1 1)
		      (0 0 0 0 0 2 1 1)
		      (0 0 0 0 0 0 0 2)
		      (0 0 0 0 0 0 0 2)
		      (0 0 0 0 0 2 1 1)
		      (0 0 0 0 2 1 1 1)
		      (0 0 0 0 1 1 1 1)
		      (0 0 0 2 1 1 1 1)
		      (0 0 0 1 1 1 1 1)
		      (0 0 2 1 1 1 1 1))))

(defmacro pl/butt (dir)
  "Generate a butt XPM function for DIR."
  (pl/pattern-defun "butt" dir 3
                    '((0 0 0))
                    '((1 1 1)
                      (0 1 1)
                      (0 0 1))
                    '((0 0 1)
                      (0 1 1)
                      (1 1 1))
		    nil nil
		    ;; 2x
		    '((0 0 0 0 0 0))
		    '((1 1 1 1 1 1)
		      (0 1 1 1 1 1)
		      (0 0 1 1 1 1)
		      (0 0 0 1 1 1)
		      (0 0 0 0 1 1)
		      (0 0 0 0 0 1))
		    '((0 0 0 0 0 1)
		      (0 0 0 0 1 1)
		      (0 0 0 1 1 1)
		      (0 0 1 1 1 1)
		      (0 1 1 1 1 1)
		      (1 1 1 1 1 1))))

(defmacro pl/chamfer (dir)
  "Generate a chamfer XPM function for DIR."
  (pl/pattern-defun "chamfer" dir 3
                    '((0 0 0))
                    '((1 1 1)
                      (0 1 1)
                      (0 0 1))
		    nil nil nil
		    ;; 2x
		    '((0 0 0 0 0 0))
		    '((1 1 1 1 1 1)
		      (0 1 1 1 1 1)
		      (0 0 1 1 1 1)
		      (0 0 0 1 1 1)
		      (0 0 0 0 1 1)
		      (0 0 0 0 0 1))))

(defmacro pl/contour (dir)
  "Generate a contour XPM function for DIR."
  (pl/pattern-defun "contour" dir 10
                    '((0 0 0 0 0 1 1 1 1 1))
                    '((1 1 1 1 1 1 1 1 1 1)
                      (0 2 1 1 1 1 1 1 1 1)
                      (0 0 2 1 1 1 1 1 1 1)
                      (0 0 0 2 1 1 1 1 1 1)
                      (0 0 0 0 1 1 1 1 1 1)
                      (0 0 0 0 2 1 1 1 1 1))
                    '((0 0 0 0 0 2 1 1 1 1)
                      (0 0 0 0 0 0 1 1 1 1)
                      (0 0 0 0 0 0 2 1 1 1)
                      (0 0 0 0 0 0 0 2 1 1)
                      (0 0 0 0 0 0 0 0 0 0))
		    nil nil
		    ;; 2x
		    '((0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1))
		    '((1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1))
		    '((0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 2 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0))))

(defmacro pl/curve (dir)
  "Generate a curve XPM function for DIR."
  (pl/pattern-defun "curve" dir 4
                    '((0 0 0 0))
                    '((1 1 1 1)
                      (2 1 1 1)
                      (0 0 1 1)
                      (0 0 2 1)
                      (0 0 0 1)
                      (0 0 0 2))
                    '((0 0 0 2)
                      (0 0 0 1)
                      (0 0 2 1)
                      (0 0 1 1)
                      (2 1 1 1)
                      (1 1 1 1))
		    nil nil
		    ;; 2x
		    '((0 0 0 0 0 0 0 0))
		    '((1 1 1 1 1 1 1 1)
		      (1 1 1 1 1 1 1 1)
		      (1 1 1 1 1 1 1 1)
		      (0 0 1 1 1 1 1 1)
		      (0 0 0 2 1 1 1 1)
		      (0 0 0 0 2 1 1 1)
		      (0 0 0 0 0 2 1 1)
		      (0 0 0 0 0 0 1 1)
		      (0 0 0 0 0 0 1 1)
		      (0 0 0 0 0 0 0 1)
		      (0 0 0 0 0 0 0 1)
		      (0 0 0 0 0 0 0 1))
		    '((0 0 0 0 0 0 0 1)
		      (0 0 0 0 0 0 0 1)
		      (0 0 0 0 0 0 0 1)
		      (0 0 0 0 0 0 1 1)
		      (0 0 0 0 0 0 1 1)
		      (0 0 0 0 0 2 1 1)
		      (0 0 0 0 2 1 1 1)
		      (0 0 0 2 1 1 1 1)
		      (0 0 1 1 1 1 1 1)
		      (1 1 1 1 1 1 1 1)
		      (1 1 1 1 1 1 1 1)
		      (1 1 1 1 1 1 1 1))))

(defmacro pl/rounded (dir)
  "Generate a rounded XPM function for DIR."
  (pl/pattern-defun "rounded" dir 6
                    '((0 0 0 0 0 0))
                    '((2 1 1 1 1 1)
                      (0 0 2 1 1 1)
                      (0 0 0 0 1 1)
                      (0 0 0 0 2 1)
                      (0 0 0 0 0 1)
                      (0 0 0 0 0 2))
		    nil nil nil
		    ;; 2x
		    '((0 0 0 0 0 0 0 0 0 0 0 0))
		    '((1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 2 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 2 1 1 1 1)
		      (0 0 0 0 0 0 0 0 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 1 1)
		      (0 0 0 0 0 0 0 0 0 0 1 1)
		      (0 0 0 0 0 0 0 0 0 0 2 1)
		      (0 0 0 0 0 0 0 0 0 0 0 1)
		      (0 0 0 0 0 0 0 0 0 0 0 1))))

(defmacro pl/roundstub (dir)
  "Generate a roundstub XPM function for DIR."
  (pl/pattern-defun "roundstub" dir 3
                    '((0 0 0))
                    '((1 1 1)
                      (0 0 1)
                      (0 0 2))
                    '((0 0 2)
                      (0 0 1)
                      (1 1 1))
		    nil nil
		    ;; 2x
		    '((0 0 0 0 0 0))
		    '((1 1 1 1 1 1)
		      (2 1 1 1 1 1)
		      (0 0 0 2 1 1)
		      (0 0 0 0 1 1)
		      (0 0 0 0 0 1)
		      (0 0 0 0 0 1))
		    '((0 0 0 0 0 1)
		      (0 0 0 0 0 1)
		      (0 0 0 0 1 1)
		      (0 0 0 2 1 1)
		      (2 1 1 1 1 1)
		      (1 1 1 1 1 1))))

(defmacro pl/slant (dir)
  "Generate a slant XPM function for DIR."
  (let* ((row-modifier (if (eq dir 'left) 'identity 'reverse)))
    (pl/wrap-defun "slant" dir 'width
                   '((width (1- (ceiling height 2))))
                   `((cl-loop for i from 0 to (1- height)
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern (/ i 2) width)))))
		   `((cl-loop for i from 0 to (1- (* height 2))
                              concat (pl/pattern-to-string (,row-modifier (pl/row-pattern (/ i 2) (* width 2)))))))))

(defmacro pl/wave (dir)
  "Generate a wave XPM function for DIR."
  (pl/pattern-defun "wave" dir 11
                    '((0 0 0 0 0 0 1 1 1 1 1))
                    '((2 1 1 1 1 1 1 1 1 1 1)
                      (0 0 1 1 1 1 1 1 1 1 1)
                      (0 0 0 1 1 1 1 1 1 1 1)
                      (0 0 0 2 1 1 1 1 1 1 1)
                      (0 0 0 0 1 1 1 1 1 1 1)
                      (0 0 0 0 2 1 1 1 1 1 1)
                      (0 0 0 0 0 1 1 1 1 1 1)
                      (0 0 0 0 0 1 1 1 1 1 1)
                      (0 0 0 0 0 2 1 1 1 1 1))
                    '((0 0 0 0 0 0 2 1 1 1 1)
                      (0 0 0 0 0 0 0 1 1 1 1)
                      (0 0 0 0 0 0 0 1 1 1 1)
                      (0 0 0 0 0 0 0 2 1 1 1)
                      (0 0 0 0 0 0 0 0 1 1 1)
                      (0 0 0 0 0 0 0 0 2 1 1)
                      (0 0 0 0 0 0 0 0 0 0 2))
		    nil nil
		    ;; 2x
		    '((0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1))
		    '((1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1))
		    '((0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 1 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1)
		      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0))))

(defmacro pl/zigzag (dir)
  "Generate a zigzag pattern XPM function for DIR."
  (pl/pattern-defun "zigzag" dir 3
                    '((1 1 1)
                      (0 1 1)
                      (0 0 1)
                      (0 0 0)
                      (0 0 1)
                      (0 1 1))
		    nil nil nil nil
		    ;; 2x
		    '((1 1 1 1 1 1)
		      (0 1 1 1 1 1)
		      (0 0 1 1 1 1)
		      (0 0 0 1 1 1)
		      (0 0 0 0 1 1)
		      (0 0 0 0 0 1)
		      (0 0 0 0 0 0)
		      (0 0 0 0 0 1)
		      (0 0 0 0 1 1)
		      (0 0 0 1 1 1)
		      (0 0 1 1 1 1)
		      (0 1 1 1 1 1))))

(defmacro pl/nil (dir)
  "Generate a XPM function that returns nil for DIR."
  `(defun ,(intern (format "powerline-nil-%s" (symbol-name dir)))
     (face1 face2 &optional height)
     nil))

(defmacro pl/utf-8 (dir)
  "Generate function that returns raw utf-8 symbols."
  (let ((dir-name (symbol-name dir))
	(src-face (if (eq dir 'left) 'face1 'face2))
	(dst-face (if (eq dir 'left) 'face2 'face1)))
    `(defun ,(intern (format "powerline-utf-8-%s" dir-name))
       (face1 face2 &optional height)
       (powerline-raw
	(char-to-string ,(intern (format "powerline-utf-8-separator-%s"
					 dir-name)))
        (list :foreground (pl/background-color ,src-face)
              :background (pl/background-color ,dst-face)
              :inverse-video nil)))))


(provide 'powerline-separators)

;;; powerline-separators.el ends here
