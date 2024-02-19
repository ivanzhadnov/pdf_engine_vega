import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class ImageToPdf {
  static Future<dynamic> imageList({required List<File?> listOfFiles}) async {
    if (listOfFiles.isEmpty) {
      throw "Your List is Empty";
    } else {
      final pdf = pw.Document();
      for (var image in listOfFiles) {
        var pdfImage = pw.MemoryImage(
          image!.readAsBytesSync(),
        );
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Image(pdfImage,fit:pw.BoxFit.contain); // Center
            },
          ),
        );
      }
      Directory appDocDir = await getApplicationDocumentsDirectory();
      final file = File("${appDocDir.path}/example.pdf");
      final bytes = await pdf.save();
      return await file.writeAsBytes(bytes,flush: true);
    }
  }
}