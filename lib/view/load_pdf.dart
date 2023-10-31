import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pdf_engine_vega/view/view_ios.dart';
import 'package:pdfium_bindings/pdfium_bindings.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';



///бинарники бибилотек https://github.com/bblanchon/pdfium-binaries

class LoadPdf{


  ///устанавливаем путь к используемой бибилотеке
  setLibraryPath()async{
    String libraryPath = '';
    final directory = await getApplicationDocumentsDirectory();
    if(Platform.isAndroid){
      libraryPath = '${directory.path}/libpdfium.so';
    }else if(Platform.isMacOS){
      libraryPath = 'libpdfium.dylib';
    }else if(Platform.isIOS){
      libraryPath = 'libpdfium_ios.dylib';
    }else if(Platform.isWindows){
      libraryPath = path.join(Directory.current.path, 'pdfium.dll');
    }else if(Platform.isLinux){
      libraryPath = path.join(Directory.current.path, 'libpdfium.so');
    }
    return true;
  }



  ///тут и на будущее в просмотрщики получить List<Image>
  Future<List<Image>> loadAssetAsList({required String pathPdf, int ration = 1, String backgroundColor = '#FF0B1730'})async{
    print(45345345);
    List<Image> result = [];
    //await setLibraryPath();
    String libraryPath = '';
    final directory = await getApplicationDocumentsDirectory();
    if(Platform.isAndroid){
      libraryPath = '${directory.path}/libpdfium.so';
    }else if(Platform.isMacOS){
      libraryPath = 'libpdfium.dylib';
    }else if(Platform.isIOS){
      libraryPath = 'libpdfium_ios_x64.dylib';
    }else if(Platform.isWindows){
      libraryPath = path.join(Directory.current.path, 'pdfium.dll');
    }else if(Platform.isLinux){
      libraryPath = path.join(Directory.current.path, 'libpdfium.so');
    }
    final pdfium = PdfiumWrap(libraryPath: libraryPath);
    final bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
    print('длина фалйа в байтах ${bytes.length}');
    PdfiumWrap document = pdfium.loadDocumentFromBytes(bytes);
    int pageCount = document.getPageCount();
    //int width = (document.getPageWidth() * ration).toInt();
    //int height = (document.getPageHeight() * ration).toInt();
    //print('$pageCount $width $height');
    for(int i = 0; i < pageCount; i++){
      print('обработали страницу $i');
      ///Uint8List bytesRend =
      document.loadPage(i)
          //.renderPageAsBytes(300, 400, /*backgroundColor:  int.parse(backgroundColor, radix: 16),*/ flags: 1);
          .savePageAsJpg('${directory.path}/out$i.jpg', qualityJpg: 80, flags: 1)
          .closePage();
      result.add(
        // Image.memory(
        //   bytesRend,
        //   fit: BoxFit.contain,
        //   colorBlendMode: BlendMode.modulate,
        //   gaplessPlayback: true,
        // ),
        !Platform.isAndroid ? Image.asset('${directory.path}/out$i.jpg')
          : Image.file(File('${directory.path}/out$i.jpg'))
      );
    }
    document.closeDocument().dispose();
    return result;
  }


  ///загрузка файла из ассета для всех ОС кроме ИОС и Web
  Future<String> loadAssetAll({required String pathPdf}) async {
    //await setLibraryPath();
    String libraryPath = '';
    final directory = await getApplicationDocumentsDirectory();
    if(Platform.isAndroid){
      libraryPath = '${directory.path}/libpdfium.so';
    }else if(Platform.isMacOS){
      libraryPath = 'libpdfium.dylib';
    }else if(Platform.isIOS){
      libraryPath = 'libpdfium_ios.dylib';
    }else if(Platform.isWindows){
      libraryPath = path.join(Directory.current.path, 'pdfium.dll');
    }else if(Platform.isLinux){
      libraryPath = path.join(Directory.current.path, 'libpdfium.so');
    }


    final pdfium = PdfiumWrap(libraryPath: libraryPath);
    ///TODO загрузка из ассета, но нам может понадобиться загрузка из локального хранилища
    final bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
    ///получить количество страниц
    ///print(pdfium.loadDocumentFromBytes(bytes).getPageCount());

    ///TODO циклом собрать массив отрендеренных страниц для отображения

    ///отрендерить страницы одну за другой и отправить их в какой нибудь лист вьюер
    pdfium
        .loadDocumentFromBytes(bytes)
        .loadPage(1)
    ///в частности перечислить флаг для отображения аннотаций
        .savePageAsJpg('${directory.path}/out.jpg', qualityJpg: 80, flags: 1)
        .closePage()
        .closeDocument()
        .dispose();

    return '${directory.path}/out.jpg';
  }

  ///загрузка файла из ассета для ИОС
  Future<File> fromAssetIOS_Android(String asset, String filename) async {
    // To open from assets, you can copy them to the app storage folder, and the access them "locally"
    Completer<File> completer = Completer();

    try {
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/$filename");
      var data = await rootBundle.load(asset);
      var bytes = data.buffer.asUint8List();
      print('длина фалйа в байтах 2 ${bytes.length}');
      await file.writeAsBytes(bytes, flush: true);
      completer.complete(file);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }

    return completer.future;
  }

  ///загрузка файла из ассета для ИОС
  Future<File> fromAssetWeb(String asset, String filename) async {
    // To open from assets, you can copy them to the app storage folder, and the access them "locally"
    Completer<File> completer = Completer();

    try {
      var dir = await getApplicationDocumentsDirectory();
      File file = File("${dir.path}/$filename");
      ///TODO загрузка из ассета, но нам может понадобиться загрузка из локального хранилища
      var data = await rootBundle.load(asset);
      var bytes = data.buffer.asUint8List();
      print('длина фалйа в байтах 2 ${bytes.length}');
      await file.writeAsBytes(bytes, flush: true);
      completer.complete(file);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }

    return completer.future;
  }

  ///выбираем тип виджета в зависимости от платформы на которой запущено приложение
  Widget child({required String pathPdf}){
    ///запасной вариант загрузки андроидов через FFI
   /* if(Platform.isAndroid){
      return FutureBuilder<String>(
          future: loadAssetAll(pathPdf: pathPdf,),
          builder: (context, snapshot) {
            return !snapshot.hasData || snapshot.data is !String
                ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                :  Image.file(File(snapshot.data!));
          });
    }
    else */
    if(Platform.isIOS || Platform.isAndroid){
      return FutureBuilder<File>(
          future: fromAssetIOS_Android(pathPdf, 'result.pdf'),
          builder: (context, snapshot) {
            if(snapshot.hasData){
             // print(snapshot.data!.path);
            }else{
              print('нет данных');
            }
            return !snapshot.hasData || snapshot.data is !File
                  ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                  :  PDFViewer_iOS(file: snapshot.data!,);
          });
    }else{
      return FutureBuilder<String>(
          future: loadAssetAll(pathPdf: pathPdf,),
          builder: (context, snapshot) {
            if(snapshot.hasData){
             // print(snapshot.data!);
            }else{
              print('нет данных');
            }
            return !snapshot.hasData || snapshot.data is !String
                ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                :  Image.asset(snapshot.data!);
          });
    }
  }

}


