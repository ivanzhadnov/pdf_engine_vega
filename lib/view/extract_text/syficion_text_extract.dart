import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../edit/annotation_class.dart';
import '../../edit/bookmark_class.dart';
import '../../util/mached_item_class.dart';

///получить количество страниц в документе
Future<int> getPagesCount({required String pathPdf})async{
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


///получить линии текста из документа для последующего выделения и отображения в оглавлении документа
void getTextLines(List<dynamic> values){
  final SendPort sendPort = values[0];
  final String filePath = values[1];
  final int page = values[2];

  late Uint8List bytes;
  bytes = (File(filePath).readAsBytesSync());

  final PdfDocument document = PdfDocument(inputBytes: bytes);
  final PdfTextExtractor extractor = PdfTextExtractor(document);
  final result = extractor.extractTextLines(startPageIndex: page);
  sendPort.send(result);
}





///пробуем сделать быстрый поиск текста
List<MatchedItemMy> searchTextInTextLines({required List<List<TextLine>> textLines, required String searchString}){
  List<MatchedItemMy> findedPoint = [];
  List searchingPhrases = searchString.replaceAll(".", "").replaceAll(",", "").replaceAll("!", "").replaceAll("?", "").split(' ');

  ///пока слово одно ищем по вхождению
  ///когда слов в звпросе много, ищем по строгому соответсвию
  if(searchingPhrases.length == 1){
    for(int i = 0; i < textLines.length; i++){
      for(int ii = 0; ii < textLines[i].length; ii++){
        if(textLines[i][ii].text.toUpperCase().replaceAll(".", "").replaceAll(",", "").replaceAll("!", "").replaceAll("?", "").contains(searchString.toUpperCase())){
          for(int iii = 0; iii < textLines[i][ii].wordCollection.length; iii++){
              if(textLines[i][ii].wordCollection[iii].text.toUpperCase().replaceAll(".", "").replaceAll(",", "").replaceAll("!", "").replaceAll("?", "").contains(searchingPhrases[0].toUpperCase())){
                MatchedItemMy find = MatchedItemMy();
                find.text = textLines[i][ii].wordCollection[iii].text;
                find.bounds = textLines[i][ii].wordCollection[iii].bounds;
                find.pageIndex = textLines[i][ii].pageIndex;
                findedPoint.add(find);
              }
          }
        }

      }
    }
  }else{
    ///сначала ищем фразу в линиях текста
    ///теперь в этих линиях ищем вхождение слов

    for(int i = 0; i < textLines.length; i++){
      for(int ii = 0; ii < textLines[i].length; ii++){
        if(textLines[i][ii].text.toUpperCase().replaceAll(".", "").replaceAll(",", "").replaceAll("!", "").replaceAll("?", "").contains(searchString.toUpperCase())){
          for(int iii = 0; iii < textLines[i][ii].wordCollection.length; iii++){
            for(int iiii = 0; iiii < searchingPhrases.length; iiii++){
              if(textLines[i][ii].wordCollection[iii].text.toUpperCase().replaceAll(".", "").replaceAll(",", "").replaceAll("!", "").replaceAll("?", "") == searchingPhrases[iiii].toUpperCase()){
                MatchedItemMy find = MatchedItemMy();
                find.text = textLines[i][ii].wordCollection[iii].text;
                find.bounds = textLines[i][ii].wordCollection[iii].bounds;
                find.pageIndex = textLines[i][ii].pageIndex;
                findedPoint.add(find);
              }
            }

          }
        }

      }
    }
  }
      return findedPoint;
}



///получить реальные размеры документа до всех обработок
///если необходимо, задаем страницу и определяем только ее размер
Future<Size> getPageSize({required String pathPdf, int? page})async{
  Size size = Size(0, 0);
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
  bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  size = document.pages[page ?? 0].size;
  return size;
}

Future<String> getPageOrientation({required String pathPdf, int? page})async{
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
    bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  return document.pageSettings.orientation.name;
}
Future<List<int>> getPageRotation({required String pathPdf, int? page})async{
  List<int> angles = [];
  late Uint8List bytes;
  try{
    bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
  }catch(e){
    bytes = (await File(pathPdf).readAsBytes());
  }
  final PdfDocument document = PdfDocument(inputBytes: bytes);
  if(page == null){
    for(int i = 0; i < document.pages.count; i++){
      angles.add(document.pages[i].rotation.index);
    }
  }else{
    angles.add(document.pages[page].rotation.index);
  }
  return angles;
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





