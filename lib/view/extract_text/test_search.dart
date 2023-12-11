import 'dart:isolate';
import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

void searchWithThread(List<dynamic> values) {
  print("Value $values");
  final SendPort sendPort = values[0];
  final String filePath = values[1];
  final String searchText = values[2];

  final file = File(filePath);
  final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
  final PdfTextExtractor extractor = PdfTextExtractor(document);
  final result = extractor.findText([searchText]);
  sendPort.send(result);
}

class PdfViewerSearch extends StatefulWidget {
  /// ...

  const PdfViewerSearch({
    super.key,
    /// ...
  });

  @override
  State<PdfViewerSearch> createState() => _PdfViewerSearchState();
}

class _PdfViewerSearchState extends State<PdfViewerSearch> {

  /// ....

  void createThread() async {
    searching.value = true;
    ReceivePort port = ReceivePort();
    final isolate = await Isolate.spawn(
      searchWithThread,
      [port.sendPort, widget.filePath, _searchTextEditingController.text],
    );
    final result = await port.first;
    isolate.kill(priority: Isolate.immediate);
    findResult.value = result;
    if (findResult.value.isNotEmpty) {
      _goPage();
    } else {
      print('${findResult.value.length} matches found.');
    }
    searching.value = false;
  }


}