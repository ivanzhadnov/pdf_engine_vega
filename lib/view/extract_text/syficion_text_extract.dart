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




