import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pdf_engine_vega/view/view_ios.dart';
import 'package:pdfium_bindings/pdfium_bindings.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../edit/annot_painter.dart';
import '../edit/annotation_class.dart';
import '../edit/annotation_core.dart';



///бинарники бибилотек https://github.com/bblanchon/pdfium-binaries

class LoadPdf{

  LoadPdf(){
    setPdfium();
  }

  PdfiumWrap? pdfium;
  ///set pdfium
  Future<bool>setPdfium()async{
    try{
      if(!Platform.isMacOS)pdfium!.dispose();
    }catch(e){}

    String libraryPath = '';
    final directory = await getApplicationDocumentsDirectory();
    if(Platform.isAndroid){
      final String localPath = directory.path;
      File file = File(localPath + '/libpdfium_android.so');
      bool exist = await file.exists();
      if(!exist){
        final asset = await rootBundle.load('assets/libpdf/libpdfium_android.so');
        final buffer = asset.buffer;
        await file.writeAsBytes(buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes));
      }
      libraryPath = file.path;
    }
    else if(Platform.isMacOS){
      libraryPath = 'libpdfium.dylib';
    }
    else if(Platform.isIOS){
      final String localPath = directory.path;
      File file = File(path.join(localPath, 'libpdfium_ios.dylib'));
      libraryPath = file.path;
    }
    else if(Platform.isWindows){
      libraryPath = path.join(Directory.current.path, 'pdfium.dll');
    }
    else if(Platform.isLinux){
      libraryPath = path.join(Directory.current.path, 'libpdfium.so');
    }
    pdfium = PdfiumWrap(libraryPath: libraryPath);
    return true;
  }

  ///получить массив со страницами в зависиомтси от ОС
  Future<List<Image>>getPagesListImage({required String pathPdf, int ration = 1, String backgroundColor = '#FF0B1730'})async {
    List<Image> result = [];
    if(Platform.isIOS){
      result = await loadAssetAsListIOS(pathPdf: pathPdf, ration: ration, backgroundColor: backgroundColor);
    }else{
      result = await loadAssetAsList(
          pathPdf: pathPdf, ration: ration, backgroundColor: backgroundColor);
    }
    return result;
  }

  ///получить количество страниц в документе
  Future<int>getPageCount({required String pathPdf,})async{
    int count = 0;
    try{
      PdfDocument _pdfDocument = await PdfDocument.openFile(pathPdf);
      count = _pdfDocument.pagesCount;
      await _pdfDocument.close();
    }catch(e){}

    return count;
  }

  ///получить байты
  Future<Uint8List>getBytesFromAsset({required String pathPdf, int ration = 1, String backgroundColor = '#FFFFFFFF', required int page})async{
    Uint8List bytes = Uint8List(0);
    PdfDocument _pdfDocument = await PdfDocument.openFile(pathPdf);
    try {
      final pdfPage = await _pdfDocument.getPage(page);
      final pdfWidth = pdfPage.width * ration;
      final pdfHeight = pdfPage.height * ration;
      final image = await pdfPage.render(
        width: pdfWidth,
        height: pdfHeight,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFFFF',
      );
      bytes = image!.bytes;
    }
    catch (e) {
      debugPrint('Load UserAgreement from Assets error: $e');
    }
    //await _pdfDocument.close();

    return bytes;
  }

  ///тут и на будущее в просмотрщики получить List<Image> for iOS
  Future<List<Image>>loadAssetAsListIOS({required String pathPdf, int ration = 1, String backgroundColor = '#FFFFFFFF'})async{
    PdfDocument _pdfDocument = await PdfDocument.openAsset(pathPdf);
    final pageCount = _pdfDocument.pagesCount;
    List<Image> result = [];
    for (int i = 1; i <= pageCount; i++) {
      try {
        final pdfPage = await _pdfDocument.getPage(i);
        final pdfWidth = pdfPage.width * ration;
        final pdfHeight = pdfPage.height * ration;
        final image = await pdfPage.render(
          width: pdfWidth,
          height: pdfHeight,
          format: PdfPageImageFormat.png,
          backgroundColor: backgroundColor,
          quality: 100,
          cropRect: i == 4 ? Rect.fromLTWH(0, 0, pdfWidth, 140) : null,
        );
        final bytes = image!.bytes;
        result.add(
          Image.memory(
            bytes,
            fit: BoxFit.contain,
            colorBlendMode: BlendMode.modulate,
            gaplessPlayback: true,
          ),
        );
      }
      catch (e) {
        debugPrint('Load UserAgreement from Assets error: $e');
      }
    }
    await _pdfDocument.close();
    return result;
  }


  ///тут и на будущее в просмотрщики получить List<Image>
  Future<List<Image>> loadAssetAsList({required String pathPdf, int ration = 1, String backgroundColor = '#FFFFFFFF'})async{

    List<Image> result = [];
    ///await setPdfium().then((value)async{
    final directory = await getApplicationDocumentsDirectory();
    //final bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
    late Uint8List bytes;
    ///загрузка из ассета, но нам может понадобиться загрузка из локального хранилища
    try{
      bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
    }catch(e){
      bytes = (await File(pathPdf).readAsBytes());
    }

    PdfiumWrap document = pdfium!.loadDocumentFromBytes(bytes);

    int pageCount = document.getPageCount();
    for(int i = 0; i < pageCount; i++){
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      ///TODO String fileName = 'render';
      document.loadPage(i)
      //.renderPageAsBytes(300, 400, /*backgroundColor:  int.parse(backgroundColor, radix: 16),*/ flags: 1);
          .savePageAsJpg('${directory.path}${Platform.pathSeparator}$fileName$i.jpg', qualityJpg: 80, flags: 1)
          .closePage();
      result.add(
          !Platform.isAndroid && !Platform.isWindows ? Image.asset('${directory.path}${Platform.pathSeparator}$fileName$i.jpg')
              : Image.file(File('${directory.path}${Platform.pathSeparator}$fileName$i.jpg'))
      );
    }
    //document.closeDocument().dispose();
    ///});

    return result;
  }

  ///загрузить в память список jpg файлов полученных из страниц ПДФ документа (IOS)
  Future<List<Uint8List>> loadRenderingImagesPaths({required String pathPdf, int ration = 1, String backgroundColor = '#FFFFFFFF'})async{
    List<Uint8List> filesBytes = [];
    if(Platform.isIOS){
      PdfDocument _pdfDocument = await PdfDocument.openAsset(pathPdf);
      final pageCount = _pdfDocument.pagesCount;
      for (int i = 1; i <= pageCount; i++) {
        try {
          final pdfPage = await _pdfDocument.getPage(i);
          final pdfWidth = pdfPage.width * ration;
          final pdfHeight = pdfPage.height * ration;
          final image = await pdfPage.render(
            width: pdfWidth,
            height: pdfHeight,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: backgroundColor,
            quality: 100,
            cropRect: i == 4 ? Rect.fromLTWH(0, 0, pdfWidth, 140) : null,
          );
          final bytes = image!.bytes;
          filesBytes.add(bytes);
        }
        catch (e) {
          debugPrint('Load UserAgreement from Assets error: $e');
        }
      }
      await _pdfDocument.close();

    }else{
      /// await setPdfium().then((value)async{
      final directory = await getApplicationDocumentsDirectory();
      late Uint8List bytes;
      ///загрузка из ассета, но нам может понадобиться загрузка из локального хранилища
      try{
        bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
      }catch(e){
        bytes = (await File(pathPdf).readAsBytes());
      }
      ///получить количество страниц
      final document = pdfium!.loadDocumentFromBytes(bytes);
      int countPages = document.getPageCount();
      //int width = document.getPageWidth().toInt();
      //int height = document.getPageHeight().toInt();
      ///циклом собрать массив отрендеренных страниц для отображения

      for(int i = 0; i < countPages; i++){
        document.loadPage(i)
            .savePageAsJpg('${directory.path}${Platform.pathSeparator}render$i.jpg', qualityJpg: 100, flags: 1)
            .closePage();
        bytes = (await File('${directory.path}${Platform.pathSeparator}render$i.jpg').readAsBytes());
        //filesBytes.add(document.loadPage(i).renderPageAsBytes(300, 400, flags: 0, /*backgroundColor:  int.parse(backgroundColor, radix: 16)*/ ));
        filesBytes.add(bytes);
      }
      /// });

    }
    return filesBytes;

  }



  ///загрузка файла PDF из ассета для всех ОС кроме ИОС и Web и помещение в файлы JPG по страницам
  Future<List<String>> loadAssetAll({required String pathPdf}) async {
    List<String> filesPaths = [];
    /// await  setPdfium().then((value)async{
    final directory = await getApplicationDocumentsDirectory();
    late Uint8List bytes;
    ///загрузка из ассета, но нам может понадобиться загрузка из локального хранилища
    try{
      bytes = (await rootBundle.load(pathPdf)).buffer.asUint8List();
    }catch(e){
      bytes = (await File(pathPdf).readAsBytes());
    }
    ///получить количество страниц
    final document = pdfium!.loadDocumentFromBytes(bytes);
    int countPages = document.getPageCount();
    ///циклом собрать массив отрендеренных страниц для отображения

    for(int i = 0; i < countPages; i++){
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      ///TODO String fileName = 'render';
      document.loadPage(i)
      ///в частности перечислить флаг для отображения аннотаций
          .savePageAsJpg('${directory.path}${Platform.pathSeparator}$fileName$i.jpg', qualityJpg: 80, flags: 1)
          .closePage();
      filesPaths.add('${directory.path}${Platform.pathSeparator}$fileName$i.jpg');
    }
    //document.closeDocument().dispose();

    // });
    return filesPaths;
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



  ///выбираем тип виджета в зависимости от платформы на которой запущено приложение
  Widget child({required String pathPdf, List<AnnotationItem>? annotations = const[], dynamic func}){
    bool withAnnot = annotations != null && annotations.isNotEmpty;

    ///запасной вариант загрузки андроидов через FFI
    if(Platform.isAndroid){
      return FutureBuilder<List<String>>(
          future: withAnnot ? AnnotationPDF().addAnnotation(pathPdf: pathPdf, annotations: annotations).then((value)=>loadAssetAll(pathPdf: value,)) : loadAssetAll(pathPdf: pathPdf,),
          builder: (context, snapshot) {
            return !snapshot.hasData
                ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                :  SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: snapshot.data!.map((item) => Image.file(File(item),)).toList()
              ),
            );
          });
    }
    else if(Platform.isIOS || Platform.isWindows){
      return FutureBuilder<File>(
          future: withAnnot ? AnnotationPDF().addAnnotation(pathPdf: pathPdf, annotations: annotations).then((value)=>fromAssetIOS_Android(value, 'result.pdf')) : fromAssetIOS_Android(pathPdf, 'result.pdf'),
          builder: (context, snapshot) {
            return !snapshot.hasData || snapshot.data is !File
                ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                :  PDFViewer_iOS(file: snapshot.data!,);
          });
    }
    else{
      return FutureBuilder<List<String>>(
          future: withAnnot ? AnnotationPDF().addAnnotation(pathPdf: pathPdf, annotations: annotations).then((value)=>loadAssetAll(pathPdf: value,)) : loadAssetAll(pathPdf: pathPdf,),
          builder: (context, snapshot) {
            List<List<List<Offset>>> lines = [];
            if(snapshot.hasData){
              lines = List.generate(snapshot.data!.length, (_) => [[]]);
            }

            return !snapshot.hasData
                ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                :  SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: snapshot.data!.map((item) => GestureDetector(
                        // onTapDown: (v){
                        //       lines[snapshot.data!.indexWhere((e) => e == item)].add([]);
                        //       func();
                        //       },
                      onPanEnd: (v){
                        print('добавили элемент');
                        lines[snapshot.data!.indexWhere((e) => e == item)].add([]);
                      },
                            onPanUpdate: (details) {
                              ///print(details.localPosition);
                              print(lines[snapshot.data!.indexWhere((e) => e == item)].length);
                              lines[snapshot.data!.indexWhere((e) => e == item)].first.add(details.localPosition);
                              //func();
                            },
                            child: Stack(
                              children: [
                                Image.asset(item),

                                ///интегрируется виджет области аннотации
                                ...annotations!.where((element) =>
                                element.page == snapshot.data!.indexWhere((e) => e == item))
                                    .toList().map((e) => e.tapChild)
                                    .toList(),
                                ...lines[snapshot.data!.indexWhere((e) => e == item)].map((_e) => FingerPaint(line:  _e,)).toList()

                                // Positioned(
                                //   left: 0,
                                //   top: 0,
                                //   child: Container(width: 50,height: 50,color: Colors.grey.withOpacity(0.4),),
                                // )
                              ],
                            ))
                    ).toList()
                )
            );
          });
    }

  }

}


