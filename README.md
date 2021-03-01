# ACADbreakDrawingByLayouts
Lisp application for splitting an AutoCAD drawings into sheets and trimming a model space by viewport frame

Load the **KG_LayoutsToDwgs.lsp** file into AutoCAD using the **_APPLOAD** command or drag and drop.
The rest of the files should be located in the AutoCAD Support Files Search folder.
For example, in:
C:\program files\autodesk\autocad 2014\support

Application functions:
Injects xrefs
Breaks blocks
Divides the drawing by the number of sheets
Crops the model to fit viewports (unless the viewport is on layer 0).

To run the application:
1.Enter **KG:BreakDwg** on the command line
2.Specify the folder to place the split sheets
3.Select the option for naming the files to be created (Sheet name only or Sheet name + Source drawing name)
4.Wait for completion


--------------------------------------------------------------------------------------------
Это Lisp приложение для разделения чертежей AutoCAD на листы и обрезки пространства модели по рамке видового экрана

Загрузите файл **KG_LayoutsToDwgs.lsp** в AutoCAD с помощью команды _APPLOAD или перетаскиванием.
Остальные файлы должны быть расположены в папке поиска вспомогательных файлов AutoCAD. 
Например в:
C:\program files\autodesk\autocad 2014\support

Функции приложения:
Внедряет xrefs
Разбивает блоки
Разделяет чертеж по количеству листов 
Обрезает модель по видовым экранам (если видовой экран не находится в слое 0). 

Чтобы запустить приложение:
1.Введите в командной строке **KG:BreakDwg**
2.Укажите папку для размещения разделенных листов
3.Выберите вариант наименования файлов которые будут созданы (Только имя листа или Имя листа + Имя исходного чертежа)
4.Дождитесь завершения

