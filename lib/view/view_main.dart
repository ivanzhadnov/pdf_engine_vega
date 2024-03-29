import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../edit/annot_buttons.dart';
import 'load_pdf.dart';

///основной виджет просмотра PDF разделе букинга
class PDFViewer extends StatefulWidget {
  ///путь к PDF файлу из локального хранилища
  final String path;
  ///настраиваем размеры виджета
  final double width;
  final double height;

  PDFViewer({
    required this.path,
    required this.width,
    required this.height
  });

  @override
  PDFViewerState createState() => PDFViewerState();
}

class PDFViewerState extends State<PDFViewer> {

  ///объявляем класс для работы с загрузкой указанного ПДФ файла
  LoadPdf load = LoadPdf();
  LoadPdf load2 = LoadPdf();
  late Timer loadControl;
  @override
  void initState() {
    super.initState();
    //RawKeyboard.instance.addListener(_keyboardCallback);
    loadControl = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if(load.loadComplite){
        setState(() {});
        loadControl.cancel();
        RawKeyboard.instance.addListener(_keyboardCallback);
      }
    });

  }

  bool scaleEnabled = false;

  void _keyboardCallback(RawKeyEvent keyEvent) {
    //print(keyEvent.data.logicalKey);
    if (keyEvent is! RawKeyDownEvent){
      //print('push');
      if (keyEvent.data.logicalKey == LogicalKeyboardKey.controlLeft) {
        scaleEnabled = false;
        if(mounted) setState(() {});
      }
    }
    if (keyEvent is! RawKeyUpEvent){
      // print('up');
      if (keyEvent.data.logicalKey == LogicalKeyboardKey.controlLeft) {
        scaleEnabled = true;
        if(mounted) setState(() {});
      }
    }


  }

  @override
  void dispose(){
    try{
      loadControl.cancel();
     RawKeyboard.instance.removeListener(_keyboardCallback);
    }catch(e){}
    super.dispose();
  }

  double zoomScale(){
    //print(MediaQuery.of(context).size.width > viewPdf.screenWidth);
    double scale = (Platform.isIOS || Platform.isAndroid) ? 1 : 0.8;

    if(MediaQuery.of(context).size.width > load.screenWidth){
          ///расчет когда поворота нет
          //scale: 2.45, обычное отображение портрет MediaQuery.of(context).size.width / (viewPdf.screenWidth + 10)
          scale = MediaQuery.of(context).size.width / (load.screenWidth + 10);
    }else{
      //scale = 0.5;
    }
    return scale;
  }



  @override
  Widget build(BuildContext context) {
    return
     Transform.scale(
        ///todo посчитать коэфф увеличения
        scale: (Platform.isIOS || Platform.isAndroid) && MediaQuery.of(context).size.width > MediaQuery.of(context).size.height ? MediaQuery.of(context).size.width / load.screenWidth * load.aspectRatioDoc : zoomScale(),
      //scale: zoomScale(),
       //scale: 1,
    alignment: Alignment.topLeft,
    child:
      SingleChildScrollView(
      child:
          load.childs(
            scaleEnabled: Platform.isAndroid || Platform.isIOS ? true: scaleEnabled,
            pathPdf: widget.path,
            mode: AnnotState.inactive,
            bookmarks: [],
            annotations: [],
            func: ()=>setState((){
              //scrollControllerAdd.jumpToPage(load.visiblyPage + 1);
              // if((Platform.isIOS) && load.visiblyPage < load.count){
              //   load2.scrollController.jumpToPage(load.visiblyPage + 1);
              //   //load2.scrollController.animateTo(load.scrollController.position.pixels  + load.screenHeight, duration: Duration(milliseconds: 100), curve: Curves.linear);
              // }

            }),
            width: widget.width,
            height: widget.height,
          ),
   )

    );
  }
}

