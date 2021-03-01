; BreakDrawingByLayouts
(defun KG:BreakDwg ( / *error* DelAllLayouts CopyModelToDwg SaveToNewDwg BindAndExplodeXrefs TextToForward GetNamingType osmodeOld dwgResultFolder layDwgWasCreated layDwgName dwgLayExists vpCurI vpSs curVP modelSs namingType oldEcho )
	(vl-load-com)
	
	(setq oldEcho (getvar "CMDECHO"))
	
	(setvar "CMDECHO" 0)
	
	(defun *error* (msg) 
		(if oldEcho (setvar "CMDECHO" oldEcho))
		(if osmodeOld (setvar "OSMODE" osmodeOld))
		(if (not (member msg '("Function cancelled" "Функция отменена" "quit / exit abort")))
			(princ (strcat "\nError: " msg "\n"))
		)
		(exit)
	)
	
	(load "LM_ViewportOutline.lsp")	
	(load "PlineExtrim.lsp")	
	(load "LM_Copy2DrawingsV1-3_KGedition.lsp")	
	(load "LM_BurstUpgradedV1-7.lsp")
	(load "FieldsToText.lsp")
	(load "LM_DrawOrderV1-2.lsp")
	(load "LM_BrowseForFolderV1-3.lsp")
	
	(defun LM:str->lst ( str del / pos )
		(if (setq pos (vl-string-search del str))
			(cons (substr str 1 pos) (LM:str->lst (substr str (+ pos 1 (strlen del))) del))
			(list str)
		)
	)
	
	(defun LM:createdirectory ( dir )
		(   
			(lambda ( fun )
				(   (lambda ( lst ) (fun (car lst) (cdr lst)))
					(vl-remove "" (LM:str->lst (vl-string-translate "/" "\\" dir) "\\"))
				)
			)
			(lambda ( root lst / dir )
				(if lst
					(if (or (vl-file-directory-p (setq dir (strcat root "\\" (car lst)))) (vl-mkdir dir))
						(fun dir (cdr lst))
					)
				)
			)
		)
		(vl-file-directory-p dir)
	)
	
	(defun DelAllLayouts (Keeper / TabName)
		(vlax-for Layout
			(vla-get-Layouts
				(vla-get-activedocument (vlax-get-acad-object))
			)
			(if
				(and
					(/= (setq TabName (strcase (vla-get-name layout))) "MODEL")
					(/= TabName (strcase Keeper))
				)
				(progn
					(vla-delete layout)
				)
				
			)
		)
	)
	
	(defun CopyModelToDwg ( dwgName / )
		(c2dwg 
			(ssget "_X" '((410 . "Model")))
			(list dwgName)
		)
	)
	
	(defun SaveToNewDwg ( dwgName / )
		(command "_.-wblock" dwgName)
		
		(if (findfile dwgName)
			(command "_Y")
		)
		
		(command "*")
		
		(if (equal 1 (logand 1 (getvar "cmdactive")))
			(command "_Y")
		)
		
	)
	
	(defun BindAndExplodeXrefs ( / insSs )
		(command "_.-xref" "_b" "*")
		
		(ConvField->Text nil)
		
		(if (setq insSs (ssget "_X" '((0 . "INSERT")(410 . "Model"))))
			(LM:burstsel insSs T)			
		)
	)
	
	(defun TextToForward ( / insSs )
		(setq insSs (ssget "_X" '((0 . "MTEXT,TEXT")(410 . "Model"))))
		
		(LM:movetotop insSs)
	)	
	
	(defun GetNamingType ( / naming )
		(initget "Лист Файл+Лист")
		(setq naming (getkword (strcat "\nВыберите вариант наименования [Лист/Файл+Лист] <Лист> :")))
		
		(if (null naming) 
			(setq naming "Лист")
		)
		naming
	)
	
	(setq dwgResultFolder (getvar "DWGPREFIX"))
	
	(if (setq dwgResultFolder (LM:browseforfolder "Текущий чертеж будет разделен по листам.\nУкажите папку для их размещения:" nil 0))
		(progn
			(setq namingType (GetNamingType))
			
			(setq osmodeOld (getvar "OSMODE"))
			
			(if (not (vl-file-directory-p dwgResultFolder))
				(LM:createdirectory dwgResultFolder)
			)
			
			(command "._undo" "_BE")
			
			(setvar "CTAB" "MODEL")
			
			(command "_.undo" "_M") 		; Исходное состояние чертежа (1)
			
			(BindAndExplodeXrefs)
			
			(command "_HATCHTOBACK")		
			
			(TextToForward)
			
			(command "_.undo" "_M") 		; Чертеж с разбитыми ссылками (2)
			
			(foreach lay (layoutlist)
				(DelAllLayouts lay)			; Удалить листы кроме текущего
				(command "_.undo" "_M") 	; Полный лист (3)
				
				(setvar "CTAB" lay)
				
				(setq layDwgWasCreated nil)
				
				(setq layDwgName 
					(if (eq namingType "Лист")
						(strcat dwgResultFolder "\\" lay ".dwg")
						(strcat dwgResultFolder "\\" (vl-filename-base (getvar "DWGNAME")) "_" lay ".dwg")
					)
				)
				
				(setq dwgLayExists (findfile layDwgName))
				
				(setq vpCurI -1)
				
				(setq vpSs (ssget "_X" '((0 . "VIEWPORT")(8 . "~0"))))
				
				(if vpSs
					(while (setq curVP (ssname vpSs (setq vpCurI (1+ vpCurI))))
						
						(vpo:main curVP)
						
						(setvar "CTAB" "MODEL")
						
						(C:OCDD)
						
						; Save current state of drawing
						(if layDwgWasCreated
							(CopyModelToDwg layDwgName)
							(progn
								(SaveToNewDwg layDwgName)
								(setq layDwgWasCreated T)
							)
						)
						
						(command "_.undo" "_B") ; Вернуть до одного листа (3)
						(command "_.undo" "_M") ; Сохранить Полный лист (3)
					)
					(progn 
						;(setvar "CTAB" "MODEL")
						(if (setq modelSs (ssget "_x" '((410 . "Model")))) 
							(command "_.Erase" modelSs "")
						)
						
						; Save current state of drawing
						(if layDwgWasCreated
							(CopyModelToDwg layDwgName)
							(progn
								(SaveToNewDwg layDwgName)
								(setq layDwgWasCreated T)
							)
						)
						
						(command "_.undo" "_B") ; Вернуть до одного листа (3)
						(command "_.undo" "_M") ; Сохранить Полный лист (3)
					)
				)
				
				(command "_.undo" "_B") ; Вернуть до одного листа (3)
				(command "_.undo" "_B") ; Вернуть до разбитых ссылок (2)
				(command "_.undo" "_M") ; Сохранить Чертеж с разбитыми ссылками (2)
			)
			
			(command "_.undo" "_B") ; Вернуть до разбитых ссылок (2)
			(command "_.undo" "_B" "_Y") ; Вернуть до исходного состояния (1)
			
			(command "._undo" "_E")
			
			(setvar "OSMODE" osmodeOld)
			
			(setvar "CMDECHO" oldEcho)
			
			(princ "Готово!\n")			
		)
	)
	
	(princ)
)

