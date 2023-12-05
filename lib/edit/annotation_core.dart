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
    ///print('перегенерили ${bookmarks!.length} ${annotations!.length}  $pathPdf');
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
                    //...annotations!.where((el) => el.page == i).toList().map((e) => e.child).toList(),
                    ...annotations!.where((el) => el.page == i && el.points.isNotEmpty).toList().map((e){
                      final _points = e.points.map((PdfPoint el) => PdfPoint(el.x,el.y)).toList().cast<PdfPoint>();
                      ///print(_points);
                      return pw.Opacity(
                        child: pw.PolyLineAnnotation(
                          points: e.subject == 'selectText' ? [..._points,..._points] : [..._points,],
                            //points: [PdfPoint(358.06640625, 290.18359375), PdfPoint(276.89453125, 290.18359375), PdfPoint(276.89453125, 499.22265625)],

                            //points: [PdfPoint(358.06640625, 290.18359375), PdfPoint(355.16796875, 288.44140625), PdfPoint(353.2734375, 287.96484375), PdfPoint(350.375, 286.8046875), PdfPoint(344.47265625, 284.58984375), PdfPoint(342.578125, 284.11328125), PdfPoint(337.6796875, 282.7109375), PdfPoint(331.77734375, 281.234375), PdfPoint(325.875, 280.49609375), PdfPoint(320.9765625, 280.49609375), PdfPoint(313.07421875, 280.49609375), PdfPoint(307.171875, 281.23046875), PdfPoint(301.26953125, 282.703125), PdfPoint(297.37109375, 284.0), PdfPoint(291.46875, 286.2109375), PdfPoint(284.56640625, 288.51171875), PdfPoint(281.66796875, 290.25), PdfPoint(276.76953125, 292.34765625), PdfPoint(273.26953125, 295.84765625), PdfPoint(270.01953125, 298.4453125), PdfPoint(269.07421875, 300.33984375), PdfPoint(267.91796875, 303.23828125), PdfPoint(267.26953125, 307.13671875), PdfPoint(267.8515625, 310.03515625), PdfPoint(269.953125, 314.93359375), PdfPoint(275.62109375, 322.21875), PdfPoint(284.12890625, 330.72265625), PdfPoint(292.63671875, 339.2265625), PdfPoint(308.9375, 351.90234375), PdfPoint(323.2734375, 362.65234375), PdfPoint(336.62890625, 373.3359375), PdfPoint(346.83984375, 380.140625), PdfPoint(358.24609375, 389.7890625), PdfPoint(367.71484375, 399.25390625), PdfPoint(370.66796875, 404.41796875), PdfPoint(372.0703125, 409.31640625), PdfPoint(372.0703125, 413.21484375), PdfPoint(369.26953125, 417.4140625), PdfPoint(365.0703125, 420.9140625), PdfPoint(358.74609375, 426.4453125), PdfPoint(348.5390625, 433.25), PdfPoint(341.25390625, 438.9140625), PdfPoint(333.82421875, 445.515625), PdfPoint(325.3203125, 454.01953125), PdfPoint(316.81640625, 462.5234375), PdfPoint(311.44921875, 467.890625), PdfPoint(303.8984375, 476.28125), PdfPoint(297.57421875, 481.8125), PdfPoint(291.25, 486.5546875), PdfPoint(288.0, 489.15234375), PdfPoint(283.80078125, 491.953125), PdfPoint(280.55078125, 494.55078125), PdfPoint(280.14453125, 494.95703125), PdfPoint(278.72265625, 496.37890625), PdfPoint(278.31640625, 496.78515625), PdfPoint(277.91015625, 497.19140625), PdfPoint(277.70703125, 497.39453125), PdfPoint(277.50390625, 497.80078125), PdfPoint(277.30078125, 498.20703125), PdfPoint(277.09765625, 498.41015625), PdfPoint(277.09765625, 498.81640625), PdfPoint(276.89453125, 499.01953125), PdfPoint(276.89453125, 499.22265625), PdfPoint(276.89453125, 499.42578125)],
                          border: e.border,
                          color: e.color,
                          author: e.author,
                          date: e.date,
                          subject: e.subject,
                          content: e.content
                        ),
                        opacity: e.subject == 'selectText' ? 0.3 : 1
                    );}).toList(),
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
    //print(file.path);
    return file.path;
  }









}