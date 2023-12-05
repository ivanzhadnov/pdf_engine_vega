import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

///добавить аннотацию
Future<String> syficionSearchTextAddAnnotation({required String pathPdf,})async{
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
    bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  //document.pages[0].annotations.add(PdfLineAnnotation([80, 42, 150, 42,], 'rwwerewrew',color: PdfColor(200, 120, 80), border: PdfAnnotationBorder(6)));
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

  document.pages[0].graphics.drawString(
      'Hello World!', PdfStandardFont(PdfFontFamily.helvetica, 12),
      brush: PdfBrushes.black, bounds: Rect.fromLTWH(0, 0, 0, 0));


  document.pages[0].graphics.drawPath(PdfPath()
  ..addPath([
    Offset(123, 33),
    Offset(24, 567),
    Offset(456, 22),
    Offset(234, 200),

  ], [0,1,1,1,]),
  // ..addPolygon([
  //   Offset(10, 100),
  //   Offset(10, 200),
  //   Offset(100, 200),
  //   Offset(100, 300),
  //   Offset(155, 150)
  // ]),

    //..addEllipse(Rect.fromLTWH(100, 100, 100, 100)),
      pen: PdfPen.fromBrush(PdfBrushes.green, width: 5.0, )
      //brush: PdfBrushes.
  );
  document.pages[0].graphics.drawPath(PdfPath()

  ..addPolygon([
    Offset(10, 100),
    Offset(10, 200),
    Offset(100, 200),
    Offset(100, 300),
    Offset(155, 150)
  ])
    ..addRectangle(Rect.fromLTWH(10, 10, 120, 100)),
    //..addEllipse(Rect.fromLTWH(100, 100, 100, 100)),
    //pen: PdfPens.black,
    brush: PdfBrushes.mintCream,

  );
  document.bookmarks.add('sdkdjg', isExpanded: true,color: PdfColor(200, 120, 80), destination: PdfDestination(document.pages[1]) );
  //document.pages.add().annotations.add(PdfLineAnnotation([80, 42, 150, 42], 'rwwerewrew',color: PdfColor(200, 120, 80), border: PdfAnnotationBorder(6)));
  //await document.save();
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



