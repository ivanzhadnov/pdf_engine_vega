import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

///просмотр PDF на платформе iOS c использованием PDFKit ядра iOS
class PDFViewer_iOS extends StatefulWidget {
  final File file;
  final int? defaultPage;
  PDFViewer_iOS({
    required this.file,
    this.defaultPage = 0
});
  @override
  PDFViewer_iOSState createState() => PDFViewer_iOSState();
}

class PDFViewer_iOSState extends State<PDFViewer_iOS> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PDFView(
      filePath: widget.file.path,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: false,
      pageFling: true,
      pageSnap: true,
      defaultPage: widget.defaultPage!,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      // if set to true the link is handled in flutter
      onRender: (_pages) {},
      onError: (error) {},
      onPageError: (page, error) {},
      onViewCreated: (PDFViewController pdfViewController) {
        //_controller.complete(pdfViewController);
      },
      onLinkHandler: (String? uri) {},
      onPageChanged: (int? page, int? total) {},
    );
  }
}