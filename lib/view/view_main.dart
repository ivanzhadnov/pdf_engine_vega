
import 'package:flutter/material.dart';
import 'load_pdf.dart';

///основной виджет просмотра PDF
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
          width: widget.width,
          height: widget.height,
          child: load.child(pathPdf: widget.path),
        );
  }
}

