(defun C:OCDD (  / en ss lst ssall bbox)
	(vl-load-com)
	(if 
		(and
			(setq sset (ssget "x" '((0 . "*POLYLINE") (8 . "VPOutline"))))
			(setq en (ssname sset 0))
		)
		(progn
			(setq bbox (ACET-GEOM-SS-EXTENTS sset T))
			(setq bbox (mapcar '(lambda(x)(trans x 0 1)) bbox))
			(setq lst (ACET-GEOM-OBJECT-POINT-LIST en 1e-3))
			(ACET-SS-ZOOM-EXTENTS sset)
			(command "_.Zoom" "0.95x")
			(if (null etrim)(load "extrim.lsp"))
			
			(etrim en 
				(polar
					(car bbox)
					(angle (car bbox)(cadr bbox))
					(* (distance (car bbox)(cadr bbox)) 1.1)
				)
			)
			(if 
				; Если после этого, снаружи полилинии остались примитивы, удалить их
				(and
					(setq ss (ssget "_CP" lst))
					(setq ssall (ssget "_X" (list (assoc 410 (entget en)))))
				)
				(progn
					(setq lst (vl-remove-if 'listp (mapcar 'cadr (ssnamex ss))))
					(foreach e1 lst (ssdel e1 ssall))
					(ACET-SS-ENTDEL ssall)
				)
			)
		)
	)
)

