import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../view/load_pdf.dart';
import 'annotation_class.dart';
import 'bookmark_class.dart';


///механизм загрузки первоначального документа PDF, инъекции в него аннотаций получкеных с сервера, генерации нового ПДФ
///и передача пути для отображения на экране или любой другой последующей обработки
class AnnotationPDF{
  final bookMarkImage = pw.SvgImage(svg:'<svg width="22" height="27" viewBox="0 0 22 27" fill="none" xmlns="http://www.w3.org/2000/svg"> <path d="M0.312012 25.6042V1.25098C0.312012 0.974834 0.53587 0.750977 0.812012 0.750977H21.4119C21.6881 0.750977 21.9119 0.974835 21.9119 1.25098V25.6716C21.9119 26.0835 21.4418 26.3187 21.1122 26.0717L10.8597 18.3912C10.6743 18.2523 10.418 18.2589 10.24 18.407L1.13189 25.9884C0.806173 26.2596 0.312012 26.0279 0.312012 25.6042Z" fill="#B11720"/></svg>');

  ///добавить имеющуюся аннотацию в документ
  Future<String>addAnnotation({required String pathPdf, List<AnnotationItem>? annotations = const[],  List<BookMarkPDF>? bookmarks = const []})async{

    print('перегенерили ${bookmarks!.length} $pathPdf');
    imageCache.clear();
    imageCache.clearLiveImages();
    ///извлекаем страницу ПДФ в картинку
    ///доступно за 200 баксов парсинг ПДФ в виджеты
    //https://github.com/DavBfr/dart_pdf/issues/565
    //final pdf = PDF.PdfDocument.load(). //PdfDocumentParserBase(bytes);
    final _load = LoadPdf();
    List<Uint8List> bytes = await _load.loadRenderingImagesPaths(pathPdf: pathPdf);
    ///добавляем эту картинку в новый ПДФ
    final pdf = pw.Document();
    for(int i = 0; i < bytes.length; i++){
   // print(bookmarks!.where((e) => e.page == i).toList().map((v) => v.page).toList());
      final image = pw.MemoryImage(bytes[i]);
      pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.fromLTRB(0,0,0,0),
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Stack(
                  children: [
                    pw.Center(
                      child: pw.Image(image),
                    ),
                    ///накладываем аннотацию
                    ...annotations!.where((el) => el.page == i).toList().map((e) => e.child).toList(),
                    ///накладываем маркер закладки
                    ...bookmarks!.where((e) => e.page == i).toList().map((v) => pw.Positioned(
                      left: v.offset.dx,
                      top: v.offset.dy,
                      child: pw.SizedBox(
                          width: 30,
                          height: 30,
                          child: bookMarkImage
                      ),
                    )).toList(),
                  ]
                ); // Center
              }));
    }

    ///сохраняем в темп
    final directory = await getApplicationDocumentsDirectory();
    String tempName = 'output.pdf';
    final file = File('${directory.path}${Platform.pathSeparator}$tempName');
    if(await file.exists()){
      ///file.delete();
    }
    await file.writeAsBytes(await pdf.save());
    ///показываем пользователю
    print(file.path);
    return file.path;
  }









}