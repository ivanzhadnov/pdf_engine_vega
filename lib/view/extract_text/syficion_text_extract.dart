import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../edit/annotation_class.dart';
import '../../edit/bookmark_class.dart';

///получить количество страниц в документе
Future<int> syficionGetPageCount({required String pathPdf})async{
  int count = 0;
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
  bytes = (await File(pathPdf).readAsBytes());
  }
  //Load an existing PDF document.
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  count = document.pages.count;
  return count;
}

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
///если необходимо, задаем страницу и определяем только ее размер
Future<Size> syficionGrtSize({required String pathPdf, int? page})async{
  Size size = Size(0, 0);
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
  bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  //print('размер страницы документа ${document.pages[page ?? 0].size}');
  size = document.pages[page ?? 0].size;
  return size;
}

///добавить аннотацию и закладки
Future<String> syficionAddAnnotation({required String pathPdf, int? page, List<AnnotationItem>? annotations, List<BookMarkPDF>? bookmarks = const []})async{
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
    bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);

  //print('размер страницы документа ${document.pages[0].size}');

   if(annotations != null){

       ///страница не задана бежим по всему документу
       for(int i = 0; i < annotations.length; i++){
         if(annotations[i].points.isNotEmpty){
           if(annotations[i].subject == 'selectText'){
             ///Add select text annotation
             if(page == null || annotations[i].page == page){
               document.pages[annotations[i].page].graphics
                 ..setTransparency(0.5, alphaBrush: 0.5, mode: PdfBlendMode.hardLight)
                 ..drawPath(
                   PdfPath()
                     ..addPath([
                       ...annotations[i].points.map((e) => Offset(e.x, e.y)).toList().cast<Offset>()
                     ], [0,...annotations[i].points.map((e) => 1).toList().cast<int>()..removeLast()]),
                   pen: PdfPen.fromBrush(PdfBrushes.blue, width: 10, dashStyle: PdfDashStyle.dashDotDot, lineCap: PdfLineCap.square, lineJoin: PdfLineJoin.round ),
                 );
             }

           }else{
             ///Add ink pen annotation
             if(page == null || annotations[i].page == page){
               document.pages[annotations[i].page].graphics
                   .drawPath(
                 PdfPath()
                   ..addPath([
                     ...annotations[i].points.map((e) => Offset(e.x, e.y)).toList().cast<Offset>()
                   ], [0,...annotations[i].points.map((e) => 1).toList().cast<int>()..removeLast()]),
                 pen: PdfPen.fromBrush(PdfBrushes.blue, width: annotations[i].border!.width / 2, dashStyle: PdfDashStyle.dashDotDot, lineCap: PdfLineCap.round, lineJoin: PdfLineJoin.round ),
               );
             }
           }
         }
       }


   }

  ///добавить закладку
  if(bookmarks!.isNotEmpty){
    document.bookmarks.add('',destination: PdfDestination(document.pages[0]) );
  }
  for(int i = 0; i < bookmarks.length; i++){
    if(bookmarks.map((e) => e.page == i && (page == null || e.page == page)).toList().isNotEmpty){
      print('добавлена закладка');
      document.bookmarks.insert(i, 'Bookmark page #${bookmarks[i].page}').destination = PdfDestination(document.pages[bookmarks[i].page]);
    }
  }

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





