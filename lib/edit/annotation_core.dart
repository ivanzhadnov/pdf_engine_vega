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
                    ...annotations!.where((el) => el.page == i && el.points!.isNotEmpty).toList().map((e){
                      print(DateTime.now());
                      final _points = e.points!.map((PdfPoint el) => PdfPoint(el.x,el.y)).toList().cast<PdfPoint>();
                      print(_points);
                      print(DateTime.now());
                      return pw.Opacity(
                        child: pw.PolyLineAnnotation(
                          //points: [..._points],
                            points: [
                              PdfPoint(413.484375, 554.30078125), PdfPoint(408.5859375, 555.0), PdfPoint(403.6875, 555.0), PdfPoint(398.7890625, 555.69921875), PdfPoint(394.890625, 555.69921875), PdfPoint(387.98828125, 555.69921875), PdfPoint(379.08203125, 555.69921875), PdfPoint(371.1796875, 555.69921875), PdfPoint(366.28125, 555.69921875), PdfPoint(360.37890625, 555.69921875), PdfPoint(355.48046875, 555.69921875), PdfPoint(352.58203125, 555.69921875), PdfPoint(350.6875, 555.69921875), PdfPoint(347.7890625, 555.69921875), PdfPoint(347.5859375, 555.69921875), PdfPoint(347.3828125, 555.69921875), PdfPoint(347.58984375, 555.69921875), PdfPoint(347.796875, 555.90234375), PdfPoint(348.00390625, 556.10546875), PdfPoint(348.2109375, 556.10546875), PdfPoint(348.41796875, 556.30859375), PdfPoint(348.625, 556.51171875), PdfPoint(348.625, 556.71484375), PdfPoint(348.83203125, 556.71484375), PdfPoint(348.83203125, 556.91796875), PdfPoint(348.83203125, 557.12109375), PdfPoint(348.83203125, 557.32421875), PdfPoint(348.83203125, 557.52734375), PdfPoint(348.62890625, 557.73046875), PdfPoint(348.22265625, 558.13671875), PdfPoint(347.328125, 558.734375), PdfPoint(346.43359375, 559.03125), PdfPoint(346.23046875, 559.03125), PdfPoint(343.33203125, 560.1875), PdfPoint(339.43359375, 562.13671875), PdfPoint(336.53515625, 563.875), PdfPoint(334.21875, 565.61328125), PdfPoint(331.90234375, 567.3515625), PdfPoint(330.48046875, 568.7734375), PdfPoint(329.8828125, 569.66796875), PdfPoint(329.28515625, 570.5625), PdfPoint(328.98828125, 571.45703125), PdfPoint(328.98828125, 572.3515625), PdfPoint(328.98828125, 573.24609375), PdfPoint(328.98828125, 575.140625), PdfPoint(328.98828125, 579.0390625), PdfPoint(328.98828125, 582.9375), PdfPoint(329.5703125, 585.8359375), PdfPoint(330.30859375, 591.73828125), PdfPoint(331.01171875, 596.63671875), PdfPoint(332.3125, 600.53515625), PdfPoint(333.7890625, 606.4375), PdfPoint(338.82421875, 616.50390625), PdfPoint(339.30078125, 618.3984375), PdfPoint(341.04296875, 621.296875), PdfPoint(343.84765625, 625.49609375), PdfPoint(346.65234375, 629.6953125), PdfPoint(349.25390625, 632.9453125), PdfPoint(350.99609375, 635.26171875), PdfPoint(352.73828125, 637.578125), PdfPoint(353.6875, 639.47265625), PdfPoint(353.6875, 639.87890625), PdfPoint(353.6875, 640.08203125), PdfPoint(353.6875, 640.48828125), PdfPoint(353.484375, 640.69140625), PdfPoint(353.078125, 641.09765625), PdfPoint(351.18359375, 641.5703125), PdfPoint(349.2890625, 642.04296875), PdfPoint(348.39453125, 642.640625), PdfPoint(347.98828125, 642.84375), PdfPoint(347.69140625, 643.73828125), PdfPoint(347.69140625, 644.14453125), PdfPoint(347.69140625, 644.55078125), PdfPoint(348.29296875, 645.4453125), PdfPoint(349.71875, 646.8671875), PdfPoint(352.62109375, 648.60546875), PdfPoint(355.5234375, 649.76171875), PdfPoint(362.4296875, 652.0625), PdfPoint(367.33203125, 654.16015625), PdfPoint(369.23046875, 655.10546875), PdfPoint(372.1328125, 655.68359375), PdfPoint(373.03125, 656.28125), PdfPoint(373.44140625, 656.28125), PdfPoint(373.44140625, 656.484375), PdfPoint(373.23828125, 656.484375), PdfPoint(372.34375, 657.08203125), PdfPoint(370.02734375, 658.8203125), PdfPoint(369.62109375, 659.2265625), PdfPoint(367.8828125, 662.125), PdfPoint(367.28515625, 663.01953125), PdfPoint(366.33984375, 664.9140625), PdfPoint(366.13671875, 665.3203125), PdfPoint(365.93359375, 665.7265625), PdfPoint(365.63671875, 666.62109375), PdfPoint(365.63671875, 666.82421875), PdfPoint(365.23046875, 667.02734375), PdfPoint(365.23046875, 667.23046875)
                            ],
                            border: e.border,
                            color: e.color,
                            author: e.author,
                            date: e.date,
                            subject: e.subject,
                            content: e.content
                        ),
                        opacity: e.subject == 'selectText' ? 0.3 : 1
                    );}).toList(),
                    ///накладываем маркер закладки
                    // ...bookmarks!.where((e) => e.page == i).toList().map((v) => pw.Positioned(
                    //   left: v.offset.dx,
                    //   top: v.offset.dy,
                    //   child: pw.SizedBox(
                    //       width: 30,
                    //       height: 30,
                    //       child: bookMarkImage
                    //   ),
                    // )).toList(),

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