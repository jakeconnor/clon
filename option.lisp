;;; option.lisp --- Option management for Clon

;; Copyright (C) 2008 Didier Verna

;; Author:        Didier Verna <didier@lrde.epita.fr>
;; Maintainer:    Didier Verna <didier@lrde.epita.fr>
;; Created:       Wed Jul  2 14:26:44 2008
;; Last Revision: Wed Jul  2 14:26:44 2008

;; This file is part of Clon.

;; Clon is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; Clon is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


;;; Commentary:

;; Contents management by FCM version 0.1.


;;; Code:

;; ============================================================================
;; The Option class
;; ============================================================================

;; #### FIXME: make abstract
(defclass option ()
  ((short-name :documentation "The option's short name."
	       :type (or null string)
	       :reader short-name
	       :initarg :short-name)
   (long-name :documentation "The option's long name."
	      :type (or null string)
	      :reader long-name
	      :initarg :long-name)
   (description :documentation "The option's description."
		:type (or null string)
		:reader description
		:initarg :description)
   (builtin :documentation "Whether this option is internal to Clon."
	    :reader builtin
	    :initform nil))
  (:default-initargs
    :short-name nil
    :long-name nil
    :description nil)
  (:documentation "The OPTION class.
This class is the basic abstract class for all options."))

(defmethod initialize-instance :after ((option option) &rest initargs)
  "Check consistency of OPTION."
  (declare (ignore initargs))
  (with-slots (short-name long-name) option
    (unless (or short-name long-name)
      (error "Option ~A: no name given." option))
    ;; #### FIXME: is this really necessary ? What about the day I would like
    ;; to add new syntax like -= etc ?
    ;; Empty long names are forbidden because of the special syntax -- (for
    ;; terminating options). However, it *is* possible to have *one* option
    ;; with an empty (that's different from NIL) short name. This option will
    ;; just appear as `-'. Note that this special option can't appear in a
    ;; minus or plus pack (of course :-), and can't have a sticky argument
    ;; either (that would look like a non-empty short name). Actually, its
    ;; usage can be one of:
    ;; - a flag, enabling `-',
    ;; - a boolean, enabling `-' or `+',
    ;; - a string, enabling `- foo'.
    ;; - a user option, behaving the same way.
    (when (and (stringp long-name) (zerop (length long-name)))
      (error "Option ~A: empty long name." option))
    (when (and (stringp short-name)
	       (stringp long-name)
	       (string= short-name long-name))
      (error "Option ~A: short and long names identical." option))
    ;; Short names can't begin with a dash because that would conflict with
    ;; the long name syntax.
    (when (and (stringp short-name)
	       (not (zerop (length short-name)))
	       (string= short-name "-" :end1 1))
      (error "Option ~A: short name begins with a dash." option))
    ;; Clon uses only long names, not short ones. But it's preferable to
    ;; reserve the prefix in both cases.
    (unless (builtin option)
      (dolist (name (list short-name long-name))
	(when (and (stringp name)
		   (or (and (= (length name) 4)
			    (string= name "clon"))
		       (and (> (length name) 4)
			    (string= name "clon-" :end1 5))))
	  (error "Option ~A: name ~S reserved by Clon." option name))))))


;; ============================================================================
;; The Flag class
;; ============================================================================

(defclass flag (option)
  ()
  (:documentation "The FLAG class.
This class implements options that don't take any argument."))

(defun make-flag (&rest keys &key short-name long-name description)
  "Make a new flag.
- SHORT-NAME is the option's short name without the dash.
  It defaults to nil.
- LONG-NAME is the option's long name, without the double-dash.
  It defaults to nil.
- DESCRIPTION is the option's description appearing in help strings.
  It defaults to nil."
  (declare (ignore short-name long-name description))
  (apply #'make-instance 'flag keys))


;; ============================================================================
;; The Argument class
;; ============================================================================

;; #### FIXME: make abstract
(defclass argument ()
  ((required :documentation "Whether the option's argument is required."
	     :reader argument-required-p
	     :initarg :argument-required)
   (name :documentation "The option's argument name."
	 :type string
	 :reader argument-name
	 :initarg :argument-name)
   (default-value :documentation "The option's default value."
		 :type (or null string)
		 :reader default-value
		 :initarg :default-value)
   (env-var :documentation "The option's associated environment variable."
	    :type (or null string)
	    :reader env-var
	    :initarg :env-var))
  (:default-initargs
    :argument-required t
    :argument-name "ARG"
    :default-value nil
    :env-var nil)
  (:documentation "The Argument class.
This class is a mixin used for non-flag options (accepting an argument)."))


;;; option.lisp ends here