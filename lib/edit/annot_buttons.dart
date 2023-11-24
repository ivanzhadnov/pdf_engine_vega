import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///перечень режимов работы с аннотацией
enum AnnotState{
  selectText,
  freeForm,
  inactive,
}


///конопки управления режимами аннотирования
class ManageAnnotButtons extends StatefulWidget {

  ManageAnnotButtons({
    super.key,
    required this.mode,
    required this.onDrawTap,
    required this.onTextTap,
    required this.onClearTap,
    required this.onAproveTap
  });

  ///состояние режима рисования в данный момент
  AnnotState mode;
  ///действие по кнопке рисовать
  Function onDrawTap;
  ///действие по кнопке выделить текст
  Function onTextTap;
  ///действие по кнопке очистить
  Function onClearTap;
  ///действие по кнопке утвердить
  Function onAproveTap;


  @override
  ManageAnnotButtonsState createState() => ManageAnnotButtonsState();

}

class ManageAnnotButtonsState extends State<ManageAnnotButtons> {

  BoxConstraints constraints = const BoxConstraints(minWidth: 40.0, minHeight: 40.0, maxWidth: 40.0, maxHeight: 40.0);

  ///TODO добавить возможность подставлять пользовательский выджет

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 50,
      child: Row(
        children: [
          if(widget.mode == AnnotState.inactive) RawMaterialButton(
            constraints: constraints,
            onPressed: ()=>widget.onDrawTap(),
            elevation: 2.0,
            fillColor: Colors.indigo,
            padding: const EdgeInsets.all(5.0),
            shape: const CircleBorder(),
            child: const Icon(CupertinoIcons.pen, color: Colors.white,),
          ),
          if(widget.mode == AnnotState.inactive) RawMaterialButton(
            constraints: constraints,
            onPressed: ()=>widget.onTextTap(),
            elevation: 2.0,
            fillColor: Colors.indigo,
            padding: const EdgeInsets.all(5.0),
            shape: const CircleBorder(),
            child: const Icon(CupertinoIcons.text_cursor, color: Colors.white,),
          ),
         if(widget.mode == AnnotState.freeForm || widget.mode == AnnotState.selectText) RawMaterialButton(
           constraints: constraints,
            onPressed: ()=>widget.onClearTap(),
            elevation: 2.0,
            fillColor: Colors.indigo,
            padding: const EdgeInsets.all(5.0),
            shape: const CircleBorder(),
            child: const Icon(CupertinoIcons.clear, color: Colors.white,),
          ),
          if(widget.mode == AnnotState.freeForm || widget.mode == AnnotState.selectText) RawMaterialButton(
            constraints: constraints,
            onPressed: ()=>widget.onAproveTap(),
            elevation: 2.0,
            fillColor: Colors.indigo,
            padding: const EdgeInsets.all(5.0),
            shape: const CircleBorder(),
            child: const Icon(CupertinoIcons.check_mark, color: Colors.white,),
          ),
        ],
      ),
    );
  }
}