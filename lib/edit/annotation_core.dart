import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../view/load_pdf.dart';
import 'annotation_class.dart';

///TODO передать местоположение для размещения аннотации
///подвигать аннотацию по экрану - OK
///сделать выбиралку типов аннотаций
///прикрутить рисовалку каляки маляки
///сделать подгрузку байттов для других ОС - OK



class AnnotationPDF{

  ///добавить имеющуюся аннотацию в документ
  Future<String>addAnnotation({required String pathPdf, List<AnnotationItem>? annotations = const[]})async{
    ///извлекаем страницу ПДФ в картинку
    ///доступно за 200 баксов парсинг ПДФ в виджеты
    //https://github.com/DavBfr/dart_pdf/issues/565
    //final pdf = PDF.PdfDocument.load(). //PdfDocumentParserBase(bytes);
    final _load = LoadPdf();
    List<Uint8List> bytes = await _load.loadRenderingImagesPaths(pathPdf: pathPdf);
    ///добавляем эту картинку в новый ПДФ
    final pdf = pw.Document();
    for(int i = 0; i < bytes.length; i++){
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
                    ...annotations!.where((el) => el.page == i).toList().map((e) => e.child).toList()
                  ]
                ); // Center
              }));
    }

    ///накладываем аннотацию



    ///сохраняем в темп
    final directory = await getApplicationDocumentsDirectory();
    String tempName = 'output.pdf';
    final file = File('${directory.path}${Platform.pathSeparator}$tempName');
    if(await file.exists()){
      file.delete();
    }
    await file.writeAsBytes(await pdf.save());
    ///показываем пользователю
    return file.path;
  }









}