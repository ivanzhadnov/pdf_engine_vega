library pdf_engine_vega;
export 'view/view_main.dart';
export 'view/load_pdf.dart';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;//

class PdfCreateWidget implements pw.Document{
  @override
  void addPage(pw.Page page, {int? index}) {
    // TODO: implement addPage
  }

  @override
  // TODO: implement document
  PdfDocument get document => throw UnimplementedError();

  @override
  void editPage(int index, pw.Page page) {
    // TODO: implement editPage
  }

  @override
  Future<Uint8List> save() {
    // TODO: implement save
    throw UnimplementedError();
  }

  @override
  // TODO: implement theme
  pw.ThemeData? get theme => throw UnimplementedError();
   // pw.Font font = pw.Font();
}

