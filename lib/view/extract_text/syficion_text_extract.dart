import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../edit/annotation_class.dart';

///получить текст из тела документа
Future<String> syficionGetText({required String pathPdf,int? startPage, int? endPage})async{
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
  bytes = (await File(pathPdf).readAsBytes());
  }
  //Load an existing PDF document.
  final PdfDocument document = PdfDocument(inputBytes: bytes);
//Extract the text from all the pages.
  String text = PdfTextExtractor(document).extractText(endPageIndex: startPage, startPageIndex: endPage,layoutText: false);
//Dispose the document.
  document.dispose();
  return text;
}

///текст строками TextLines на странице
Future<List<TextLine>> syficionGetTextLines({required String pathPdf, int? startPage, int? endPage})async{
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
    bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  List<TextLine> text = PdfTextExtractor(document).extractTextLines(endPageIndex: startPage, startPageIndex: endPage);
  document.dispose();
  return text;
}

///возвращаем найденый текст, страница, координаты строки
Future<List<MatchedItem>> syficionSearchText({required String pathPdf, required String searchString, int? startPage, int? endPage})async{
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
    bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  List<MatchedItem> text = PdfTextExtractor(document).findText([searchString],startPageIndex: startPage, endPageIndex: endPage);
  document.dispose();
  return text;
}

Future<List<MatchedItem>> syficionSearchTTT({required String pathPdf, required String searchString, int? startPage, int? endPage})async{

  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
    bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  ///document.sections.
  List<MatchedItem> text = PdfTextExtractor(document).findText([searchString],startPageIndex: startPage, endPageIndex: endPage);
  document.dispose();
  return text;
}

///получить реальные размеры документа до всех обработок
Future<Size> syficionGrtSize({required String pathPdf,})async{
  Size size = Size(0, 0);
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
  bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);

  print('размер страницы документа ${document.pages[0].size}');
  size = document.pages[0].size;
  return size;
}

///добавить аннотацию и закладки
Future<String> syficionAddAnnotation({required String pathPdf,List<AnnotationItem>? annotations})async{
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
    bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);

  print('размер страницы документа ${document.pages[0].size}');

   if(annotations != null){

     for(int i = 0; i < annotations.length; i++){
       if(annotations[i].points.isNotEmpty){
               document.pages[annotations[i].page].graphics.drawPath(
          PdfPath()
        ..addPath([
          ...annotations[i].points.map((e) => Offset(e.x, e.y)).toList().cast<Offset>()
        ], [0,...annotations[i].points.map((e) => 1).toList().cast<int>()..removeLast()]),
          pen: PdfPen.fromBrush(PdfBrushes.blue, width: annotations[i].border!.width / 2, dashStyle: PdfDashStyle.dashDotDot, lineCap: PdfLineCap.round, lineJoin: PdfLineJoin.round )
      );
       }

     }
   }


/*
  ///добавить аннотацию
  document.pages[0].annotations.add(PdfPolygonAnnotation(  [
    50,
    298,
    100,
    325,
    200,
    355,
    300,
    230,
    180,
    230
  ], 'PolygonAnnotation',color: PdfColor(255, 0, 0),innerColor: PdfColor(255, 0, 255)));

  ///добавить текст
  // document.pages[0].graphics.drawString(
  //     'Hello World!', PdfStandardFont(PdfFontFamily.helvetica, 12),
  //     brush: PdfBrushes.black, bounds: Rect.fromLTWH(0, 0, 0, 0));

  ///добавить кривую
  document.pages[0].graphics.drawPath(PdfPath()
  ..addPath([
    Offset(123, 33),
    Offset(24, 567),
    Offset(456, 22),
    Offset(234, 200),

  ], [0,1,1,1,]),
      pen: PdfPen.fromBrush(PdfBrushes.blue, width: 5.0, dashStyle: PdfDashStyle.dashDotDot, lineCap: PdfLineCap.round, lineJoin: PdfLineJoin.round )
  );
  
  ///добавить полигон
  document.pages[0].graphics.drawPath(PdfPath()
  ..addPolygon([
    Offset(24, 24),
    Offset(134, 24),
    Offset(134, 114),
    Offset(24, 114),
  ])
    ///добавить прямоугольник
    ..addRectangle(Rect.fromLTWH(24, 24, 134, 114)),
    //..addRectangle(Rect.fromLTWH(10, 10, 120, 100)),
    pen: PdfPen.fromBrush( PdfBrushes.green, width: 4.0, dashStyle: PdfDashStyle.dashDotDot, lineCap: PdfLineCap.round, lineJoin: PdfLineJoin.round,),
    //brush: PdfBrushes.gray,

  );
  
  ///добавить закладку
  document.bookmarks.add('sdkdjg', isExpanded: true,color: PdfColor(200, 120, 80), destination: PdfDestination(document.pages[1]) );
*/
  ///сохраняем в темп
  final directory = await getApplicationDocumentsDirectory();
  String tempName = 'output.pdf';
  final file = File('${directory.path}${Platform.pathSeparator}$tempName');
  if(await file.exists()){
    ///file.delete();
  }
  await file.writeAsBytes(await document.save());
  ///показываем пользователю
  //print(file.path);
  return file.path;
}





