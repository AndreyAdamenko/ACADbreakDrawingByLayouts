(defun C:CFT ()(ConvField->Text t))
(defun C:CFTAll ()(ConvField->Text nil))
(defun C:CFTSEL( / *error* Doc ss CountField)
   (vl-load-com)  
  (defun *error* (msg)(princ msg)(vla-endundomark doc)(princ))
  (setq Doc (vla-get-activedocument (vlax-get-acad-object)))
 (vla-startundomark Doc)
  (if (setq ss (ssget "_:L"))
    (progn
      (setq CountField 0)
     (foreach obj (mapcar (function vlax-ename->vla-object)
	            (vl-remove-if (function listp)
		      (mapcar (function cadr) (ssnamex ss))))
       (setq CountField (ClearField Obj CountField))
       )
      (princ "\nConverting Field in ")(princ CountField)
      (princ " text's")
      )
    )
(vla-endundomark Doc)
(command "_.Regenall")  
  )
(defun ClearField ( Obj CountField / txtstr att )
  (cond
        ((and (vlax-write-enabled-p Obj)
		 (= (vla-get-ObjectName obj) "AcDbBlockReference")
		 (= (vla-get-HasAttributes obj) :vlax-true)
	    ) ;_ end of and
	  (foreach att 	(append (vlax-invoke obj 'Getattributes)
                                (vlax-invoke obj 'Getconstantattributes)
                                )
            (setq txtstr (vla-get-Textstring att))
	    (vla-put-Textstring att "")
	    (vla-put-Textstring att txtstr)
	    (setq CountField (1+ CountField))
	  ) ;_ end of foreach
	)
	((and (vlax-write-enabled-p Obj)
		 (vlax-property-available-p Obj 'TextString)
	    ) ;_ end of and
	    (setq txtstr (vla-get-Textstring Obj))
	    (vla-put-Textstring Obj "")
	    (vla-put-Textstring Obj txtstr)
	    (setq CountField (1+ CountField))
	)
        ((and (vlax-write-enabled-p Obj) ;_Table
              (eq (vla-get-ObjectName Obj) "AcDbTable")
              )
         (and (vlax-property-available-p Obj 'RegenerateTableSuppressed)
                (vla-put-RegenerateTableSuppressed Obj :vlax-true)
              )
         (VL-CATCH-ALL-APPLY 
         '(lambda (col row / i j)
            (setq i '-1)
            (repeat col
              (setq i (1+ i) j '-1)
              (repeat row
                (setq j (1+ j))
                (if (= (vla-GetCellType Obj j i) acTextCell)
                  (vla-SetText Obj j i (vla-GetText Obj j i))
                  )
                (setq CountField (1+ CountField))
                )
              )
            )
         (list
           (vla-get-Columns Obj)
           (vla-get-Rows Obj)
           )
           )
         (and (vlax-property-available-p Obj 'RegenerateTableSuppressed)
                (vla-put-RegenerateTableSuppressed Obj :vlax-false)
              )
         )
        (t nil)
        )
  CountField
  )
(defun ConvField->Text ( Ask / Doc *error* ClearFieldInAllObjects
	      )
;;; t - Ask user nil - convert
;;; Как все поля чертежа сразу преобразовать в текст?
;;; Convert Field to Text
;;; Posted Vladimir Azarko (VVA)
;;; http://forum.dwg.ru/showthread.php?t=20190&page=2
;;; http://forum.dwg.ru/showthread.php?t=20190
  (vl-load-com)  
  (defun *error* (msg)(princ msg)
   (mip:layer-status-restore)
   (vla-endundomark doc)(princ)
  )
 (defun loc:msg-yes-no ( title message / WScript ret)
(setq WScript (vlax-get-or-create-object "WScript.Shell"))
(setq ret (vlax-invoke-method WScript "Popup" message "0" title (+ 4 48)))
(vlax-release-object WScript)
(= ret 6)  
)

(defun ClearFieldInAllObjects (Doc / txtstr tmp txt count CountField)
  (setq  CountField 0)  
  (vlax-for Blk	(vla-get-Blocks Doc)
    (if	(equal (vla-get-IsXref Blk) :vlax-false) ;;;kpbIc http://forum.dwg.ru/showpost.php?p=396910&postcount=30
      (progn
	(setq count 0
	      txt (strcat "Changed " (vla-get-name Blk))
	      )
	(grtext -1 txt)
;;;        (terpri)(princ "=================== ")(princ txt)
      (if (not (wcmatch (vla-get-name Blk) "`*T*")) ;_exclude table
      (vlax-for	Obj Blk
	(setq count (1+ count))
	(if (zerop(rem count 10))(grtext -1 (strcat txt " : " (itoa count))))
        (setq CountField (ClearField Obj CountField))
      ) ;_ end of vlax-for
        )
      )
    ) ;_ end of if
  ) ;_ end of vlax-for
 (vl-cmdf "_redrawall")
 CountField 
)
(setq Doc (vla-get-activedocument (vlax-get-acad-object)))
(mip:layer-status-save)(vla-startundomark Doc)
 (if (or (not Ask )
	 (if (= (getvar "DWGCODEPAGE") "ANSI_1251")
	   (loc:msg-yes-no "Внимание"
	     "Все поля будут преобразованы в текст !!!\nПродолжить?"
	     )
	   (loc:msg-yes-no "Attension"
	     "All fields will be transformed to the text!!!\nto Continue?"
	     )
	   )
	 )
 (progn
   (princ "\nConverting Field in ")
   (princ (ClearFieldInAllObjects Doc))
   (princ " text's")
   )
   (princ)
 )
(mip:layer-status-restore)(vla-endundomark Doc)
(command "_.Regenall")  
(princ)
)

(defun mip:layer-status-restore	()
  (foreach item	*MIP_LAYER_LST*
    (if	(not (vlax-erased-p (car item)))
      (vl-catch-all-apply
	'(lambda ()
	   (vla-put-lock (car item) (cdr (assoc "lock" (cdr item))))
	   (vla-put-freeze
	     (car item)
	     (cdr (assoc "freeze" (cdr item)))
	   ) ;_ end of vla-put-freeze
	 ) ;_ end of lambda
      ) ;_ end of vl-catch-all-apply
    ) ;_ end of if
  ) ;_ end of foreach
  (setq *MIP_LAYER_LST* nil)
) ;_ end of defun
(defun mip:layer-status-save ()
  (setq *MIP_LAYER_LST* nil)
  (vlax-for item (vla-get-layers
		   (vla-get-activedocument (vlax-get-acad-object))
		 ) ;_ end of vla-get-layers
    (setq *MIP_LAYER_LST*
	   (cons (list item
		       (cons "freeze" (vla-get-freeze item))
		       (cons "lock" (vla-get-lock item))
		 ) ;_ end of cons
		 *MIP_LAYER_LST*
	   ) ;_ end of cons
    ) ;_ end of setq
    (vla-put-lock item :vlax-false)
    (if	(= (vla-get-freeze item) :vlax-true)
      (vl-catch-all-apply
	'(lambda () (vla-put-freeze item :vlax-false))
      ) ;_ end of vl-catch-all-apply
    ) ;_ end of if
  ) ;_ end of vlax-for
) ;_ end of defun