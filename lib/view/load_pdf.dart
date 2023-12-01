import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_engine_vega/view/view_ios.dart';
import 'package:pdf_engine_vega/view/widgets/annot_eraser.dart';
import 'package:pdfium_bindings/pdfium_bindings.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:visibility_detector/visibility_detector.dart';

import '../edit/annot_buttons.dart';
import '../edit/annot_painter.dart';
import '../edit/annotation_class.dart';
import '../edit/annotation_core.dart';

import '../edit/bookmark_class.dart';
import '../edit/line_class.dart';
import '../util/piont_in_circle.dart';
import 'extract_text/syficion_text_extract.dart';



///бинарники бибилотек https://github.com/bblanchon/pdfium-binaries
///обработка загрузки и конвертации PDF файла под разные ОС и последующее отображение на экране пользователя
///обработка отображения и добавления аннотирования в документ
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
      PdfDocument pdfDocument = await PdfDocument.openFile(pathPdf);
      count = pdfDocument.pagesCount;
      await pdfDocument.close();
    }catch(e){}

    return count;
  }

  String pathDoument = '';
  Future<String> get documentText => getText(pathPdf:pathDoument);
  ///получить текст из тела документа
  Future<String>getText({required String pathPdf,})async{
    //String text = await PDFTextExtractionWrapping().extractText(pathPdf);
    String text = await syficionGetText(pathPdf:pathPdf);
    return text;
  }

  ///текст строками TextLines
  Future<List<sf.TextLine>>getTextLines({required String pathPdf, required int page})async{
    //String text = await PDFTextExtractionWrapping().extractText(pathPdf);
    List<sf.TextLine> text = []; await syficionGetTextLines(pathPdf:pathPdf, startPage: null, endPage: null).then((value) => text = value);
    //print(text.last.text);
    //print(text);
    return text;
  }
  
  ///поиск текста в документе
  searchText({required String pathPdf, required int page}){
    syficionSearchText(pathPdf: pathPdf, searchString: 'Less').then((value) => print(value.map((e) => e.bounds).toList()));
  }

  ///получить байты
  Future<Uint8List>getBytesFromAsset({required String pathPdf, int ration = 1, String backgroundColor = '#FFFFFFFF', required int page})async{
    Uint8List bytes = Uint8List(0);
    PdfDocument pdfDocument = await PdfDocument.openFile(pathPdf);
    try {
      final pdfPage = await pdfDocument.getPage(page);
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
    PdfDocument pdfDocument = await PdfDocument.openAsset(pathPdf);
    final pageCount = pdfDocument.pagesCount;
    List<Image> result = [];
    for (int i = 1; i <= pageCount; i++) {
      try {
        final pdfPage = await pdfDocument.getPage(i);
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
    await pdfDocument.close();
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
      //String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'render';
      imageCache.evict(FileImage(File('${directory.path}${Platform.pathSeparator}$fileName$i.jpg')), includeLive: true);
      imageCache.clear();
      imageCache.clearLiveImages();
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
      PdfDocument pdfDocument = await PdfDocument.openAsset(pathPdf);
      final pageCount = pdfDocument.pagesCount;
      for (int i = 1; i <= pageCount; i++) {
        try {
          final pdfPage = await pdfDocument.getPage(i);
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
      await pdfDocument.close();

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
        imageCache.evict(FileImage(File('${directory.path}${Platform.pathSeparator}render$i.jpg')), includeLive: true);
        imageCache.clear();
        imageCache.clearLiveImages();
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
      //String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      String fileName = 'render';
      imageCache.evict(FileImage(File('${directory.path}${Platform.pathSeparator}$fileName$i.jpg')), includeLive: true);
      imageCache.clear();
      imageCache.clearLiveImages();
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
      File file = File("${dir.path}${Platform.pathSeparator}$filename");
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

  List<List<DrawLineItem>> lines = [];
  ///установщик оси У для выделения текста
  double yLine = -1;


  ///массив для опредделения размеров окна с отображаемой страницей
  List<GlobalKey> globalKeys = [];

  String oldPath = '';
  List<String> oldListPaths = [];
  int _key = DateTime.now().millisecondsSinceEpoch;

  ///индикация активной страницы и перелистывание страниц
  int visiblyPage = 1;
  ScrollController scrollController = ScrollController();

  ///возвращаем уже сохраненные картинки с ПДФ для блокировки нежелательной перерисовки
  Future<List<String>> returnOldList()async{
    return oldListPaths;
  }

  ///обрабатываем нажатие по скролл контроллеру
  changePage(int page, setState){
    if(oldListPaths.length > 1){
      final RenderObject? renderBoxRed = globalKeys[page].currentContext!.findRenderObject();
      final height = renderBoxRed?.semanticBounds.height;
      final width = renderBoxRed?.paintBounds.width;
      scrollController.jumpTo(height! * page - 30);
      setState();
    }
  }

  ///переменные для работы с ластиком
  double eraseRadius = 10.0;
  Offset erasePosition = const Offset(-100, -100);
  List<List<List<Offset>>> erasePositions = [];
  ///формируем разорванные ластиком массивы, после добавим их в основной массив
  List<DrawLineItem> brokenLists = [];
  ///формируем список массивов, которые нужно будет удалить после обработки на пересечение с ластиком
  List<DrawLineItem> indexToDelete = [];


  ///выбираем тип виджета в зависимости от платформы на которой запущено приложение
  Widget child({
    ///путь к файлу PDF, может быть как asset так и из хранилища документов
    required String pathPdf,
    ///массив аннотаций полученых с сервера
    List<AnnotationItem>? annotations = const [],
    ///требуемая к выполнению внешняя функция
    dynamic func,
    ///направление прокрутки при просмотре файла
    Axis? scrollDirection = Axis.vertical,
    ///подключение механизмов работы с аннотациями
    bool? editable = false,
    ///получаем режим рисования из вне
    required AnnotState mode,
    ///номера страниц на которых установлены закладки
    List<BookMarkPDF>? bookmarks,
    ///поворот документа
    int rotation = 0,
    ///размеры экрана
    double? width,
    double? height,
  }){
    pathDoument = pathPdf;
    imageCache.clear();
    imageCache.clearLiveImages();
    bool withAnnot = annotations != null || annotations!.isNotEmpty;
    ///обработка нажатия на страницу
    void onTap(int index){
      ///уточняем номер текущей страницы
      visiblyPage = index;
      try{
        func();
      }catch(e){}
    }
    ///обработка начала рисования
    void onPanStart(v, int index, setState){
      if(mode == AnnotState.selectText || mode == AnnotState.freeForm){
        lines[index].add(DrawLineItem());
        yLine = -1;
        setState((){});
      }else if(mode == AnnotState.erase){
        erasePositions[index].add([]);
        setState((){});
      }
    }
    ///обработка завершения рисования линии и подготовка новой линии
    void onPanEnd(v, int index, setState){
      ///формируем ровную и без лишних точек линию выделения текста, так эстетичнее и уменьшается нагрузка
      if(mode == AnnotState.selectText){
        final temp = lines[index].last.line;
        lines[index].last.line = [temp.first, temp.last];
        setState((){});
        try{
          func();
        }catch(e){}
      }else if(mode == AnnotState.erase){
        erasePositions[index] = [];
      }
    }
    ///обработка рисования
    void onPanUpdate(DragUpdateDetails details, int index, setState) {
      Offset current = Offset(details.localPosition.dx, details.localPosition.dy);
      if(mode == AnnotState.selectText || mode == AnnotState.freeForm){
        final RenderObject? renderBoxRed = globalKeys[index].currentContext!.findRenderObject();
        final maxHeight = renderBoxRed?.paintBounds.height;
        final maxWidth = renderBoxRed?.paintBounds.width;
        double x = 0;
        double y = 0;


        if(current.dx < maxWidth! && current.dx > 0){
          x = current.dx;
        }else{
          x = current.dx > 0 ? maxWidth - 10 : 0;
        }
        if(current.dy < maxHeight! && current.dy > 0){
          y = current.dy;
        }else{
          y = current.dy > 0 ? maxHeight - 10 : 0;
        }
        if(mode == AnnotState.selectText){
          ///рисуем горизонтальную прямую
          if(yLine == -1){
            yLine = y;
          }
          lines[index].last.line.add(Offset(x, yLine));
        }else{
          ///просто рисуем кривую
          lines[index].last.line.add(Offset(x, y));
        }
        setState((){});
        try{
          func();
        }catch(e){}
      }else if(mode == AnnotState.erase){
        erasePosition = Offset(current.dx, current.dy);
        setState((){});
        if(erasePositions[index].last.isNotEmpty){
          erasePositions[index].last.add(erasePosition);
          // if(erasePositions[index].last.last.dx > erasePosition.dx - (eraseRadius)
          //     || erasePositions[index].last.last.dx < erasePosition.dx + (eraseRadius)
          //     || erasePositions[index].last.last.dy > erasePosition.dy - (eraseRadius )
          //     || erasePositions[index].last.last.dy < erasePosition.dy + (eraseRadius )
          // ){

//print(lines[index].length);
            for(int i = 0; i < lines[index].length; i++){
              //print('in cycle #1');
              for(int ii = 0; ii < lines[index][i].line.length; ii++){
                //print('in cycle #2');
                bool result = belongsToCircle(x: lines[index][i].line[ii].dx, y: lines[index][i].line[ii].dy, centerX: erasePosition.dx, centerY: erasePosition.dy, radius: eraseRadius);
                if(result){
                  ///надо удалить из brokenLists массивы, где присутсвует удаляемая точка
                  brokenLists.removeWhere((e) =>
                  ///удаляем списки где есть полное совпадение с родительским списком
                  e.toJson().toString().contains(lines[index][i].toJson().toString())
                      ///удаляем пустые списки
                      || e.line.isEmpty
                      ///удаляем короткие списки
                      || e.line.length < 2
                    ///удаляем списки где есть есть попадание в круг стерки
                    //|| brokenLists.map((e) => e.line.map((l) => belongsToCircle(x: l.dx, y: l.dy, centerX: erasePosition.dx, centerY: erasePosition.dy, radius: eraseRadius) == true).toList()).toList().isNotEmpty
                  );
                  //print('принадлежит ли точка линии кругу ластика ${result}, ластик $erasePosition, точка ${lines[index][i].line[ii]} index ${ii}');
                  int splitIndex = ii; // Индекс, на котором нужно разорвать массив
                  final tmpFirst = DrawLineItem()..color = lines[index][i].color..thickness=lines[index][i].thickness..undoLine=lines[index][i].undoLine..undoColor=lines[index][i].undoColor..undoThickness=lines[index][i].undoThickness;
                  tmpFirst.line = lines[index][i].line.map((e) => e).toList().sublist(0, splitIndex);
                  final tmpSecond = DrawLineItem()..color = lines[index][i].color..thickness=lines[index][i].thickness..undoLine=lines[index][i].undoLine..undoColor=lines[index][i].undoColor..undoThickness=lines[index][i].undoThickness;
                  tmpSecond.line = lines[index][i].line.map((e) => e).toList().sublist(splitIndex);
                  if(brokenLists.length < 100){
                    brokenLists.add(tmpFirst);
                    brokenLists.add(tmpSecond);
                    indexToDelete.add(lines[index][i]);
                  }else{

                  }


                }
              }
          }


          for(int i = 0; i < indexToDelete.length; i++){
            //print('in cycle #3');
            lines[index].removeWhere((e) => e.toJson().toString() == indexToDelete[i].toJson().toString());
          }
          brokenLists..removeWhere((e) => e.line.isEmpty)..removeWhere((el) => el.line.length < 4);
          brokenLists.unique((x) => x.toJson().toString());
          for(int i = 0; i < brokenLists.length; i++){
            //print('in cycle #4');
            lines[index].add(brokenLists[i]);
          }
          lines[index]..removeWhere((e) => e.line.isEmpty)..removeWhere((el) => el.line.length < 4);
          lines[index].unique((x) => x.toJson().toString());
          //log('${lines[index].map((e) => e.line)}');
          //log('${lines[index].map((e) => e.line.length)}');
          brokenLists = [];
          indexToDelete = [];

          //}
        }else{
          erasePositions[index].last.add(erasePosition);
        }
      }
    }
    ///обработка прокрутки страниц и установка номера активной страницы
    void onVisibilityChanged(VisibilityInfo info) {
      visiblyPage = int.parse(info.key.toString().replaceAll('[<\'', '').replaceAll('\'>]', ''));
      ///print('${DateTime.now()} page $visiblyPage');
      try{
        func();
      }catch(e){}
    }

    ///запасной вариант загрузки андроидов через FFI
    if(Platform.isAndroid){
      return FutureBuilder<List<String>>(
          future: withAnnot ? AnnotationPDF().addAnnotation(pathPdf: pathPdf, annotations: annotations).then((value)=>loadAssetAll(pathPdf: value,)) : loadAssetAll(pathPdf: pathPdf,),
          builder: (context, snapshot) {
            return !snapshot.hasData
                ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                :  SingleChildScrollView(
              ///TODO scrollDirection: scrollDirection!,
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
          future: withAnnot ?
          oldPath != pathPdf ? AnnotationPDF().addAnnotation(pathPdf: pathPdf, annotations: annotations, bookmarks: bookmarks).then((value)=>loadAssetAll(pathPdf: value,))
              : returnOldList()
              : loadAssetAll(pathPdf: pathPdf,),
          builder: (context, snapshot) {
            //print('перерисовали');

            if(snapshot.hasData /*&& lines.length != snapshot.data!.length */ && oldPath != pathPdf){
              ///блокируем перерисовки
                lines = List.generate(snapshot.data!.length, (_) => [DrawLineItem()]);
                erasePositions = List.generate(snapshot.data!.length, (_) => []);
                globalKeys = List.generate(snapshot.data!.length, (_) => GlobalKey());
                oldListPaths = snapshot.data!;
                oldPath = pathPdf;

            }
            List<Widget> children = snapshot.hasData ? snapshot.data!.map((item) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setState){
                  ///номер страницы
                  int index = snapshot.data!.indexWhere((e) => e == item);
                  imageCache.evict(FileImage(File(item)), includeLive: true);
                  return GestureDetector(
                      onTap: ()=>onTap(index),
                      onPanStart: (v)=>onPanStart(v, index, setState),
                      onPanEnd: (v)=>onPanEnd(v, index, setState),
                      onPanUpdate: (details)=>onPanUpdate(details, index, setState),
                      child: VisibilityDetector(
                          key: ValueKey("$index"),
                          onVisibilityChanged: (VisibilityInfo info)=>onVisibilityChanged(info),
                          child:RotatedBox(
                              quarterTurns: rotation,
                              child: Container(
                                  key: globalKeys[index],
                                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                  child: Stack(
                                    children: [
                                      ///поворт блока надо совместить с нарисованными линиями
                                      Image.asset(
                                        key: ValueKey('$_key'),
                                        semanticLabel: '$_key',
                                        item,
                                        width: width,
                                        //height: height,
                                        fit: (rotation == 0 || rotation == 2) ? BoxFit.fitWidth : BoxFit.fitHeight,),
                                      // Image.file(File(item), width: width,
                                      //   //height: height,
                                      //   fit: (rotation == 0 || rotation == 2) ? BoxFit.fitWidth : BoxFit.fitHeight,),
                                      ///использован этот виджет т.к. он не кеширует картинки
                                      //Image.memory(File(item).readAsBytesSync(), width: width,
                                      //height: height,
                                      //   fit: (rotation == 0 || rotation == 2) ? BoxFit.fitWidth : BoxFit.fitHeight,),
                                      ///Text('$_key', style: TextStyle(color: Colors.black),),
                                      ///интегрируется виджет области аннотации
                                      ...annotations.where((element) =>
                                      element.page == index)
                                          .toList().map((e) => e.tapChild)
                                          .toList(),
                                      ...lines[index].map((e)=>FingerPaint(line:  e.line, mode: mode == AnnotState.erase ? AnnotState.freeForm : mode, color: e.color, thickness: e.thickness, )).toList(),
                                      //...erasePositions[index].map((e)=>FingerPaint(line:  e, mode: AnnotState.erase, color: Colors.white, thickness: eraseRadius * 2, )).toList(),
                                      ///указатель ластика
                                      if(mode == AnnotState.erase) AnnotEraser(eraseRadius: eraseRadius, erasePosition: erasePosition,),
                                      /*ManageAnnotButtons(
                                  mode: buttons[snapshot.data!.indexWhere((e) => e == item)],
                                  onDrawTap: ()=>setState(()=>buttons[index] = AnnotState.freeForm),
                                  onTextTap: ()=>setState(()=>buttons[index] = AnnotState.selectText),
                                  onClearTap: ()=>setState((){
                                    buttons[index] = AnnotState.inactive;
                                    lines.removeAt(index);
                                  }),
                                  onAproveTap: ()=>addCommentDialog(context).then((value){
                                    if(value){
                                      AnnotationItem newAnnot = AnnotationItem(
                                        subject: buttons[index].name,
                                        author: 'Народ',
                                        page: index,
                                        annotationType: AnnotationType.inkAnnotation,
                                        color: buttons[index] == AnnotState.freeForm ? PDF.PdfColors.blue : PDF.PdfColor.fromHex('#00ff0080'),
                                        border: PDF.PdfBorder(PDF.PdfDocument(), buttons[index] == AnnotState.freeForm ? 4 : 12),
                                        //interiorColor: PDF.PdfColors.blue,
                                        pointsInk:lines[index].map((e) => AnnotationItem(page: 0, annotationType: AnnotationType.inkAnnotation).convertPointsType(e)).toList()  ,
                                        content: commentBody,
                                        date: DateTime.now(),

                                      );
                                      //print(AnnotationItem.fromMap({'uuid': null, 'page': 2, 'annotationType': 'inkAnnotation', 'color': '#00ff0080', 'border': null, 'author': 'Народ', 'date': 1700828655376, 'content': 'мссмти', 'subject': 'selectText', 'points': [], 'pointsInk': [[{'x': 67.0625, 'y': 258.1754150390625}, {'x': 446.60546875, 'y': 258.1754150390625}], [{'x': 66.55078125, 'y': 277.0230712890625}, {'x': 392.55078125, 'y': 277.0230712890625}], [{'x': 63.05078125, 'y': 305.4957275390625}, {'x': 376.9375, 'y': 305.4957275390625}]]}));
                                      newAnnot.pointsInk = lines[index].map((e) => newAnnot.convertPointsType(e)).toList();
                                      annotations.add(newAnnot);
                                      setState((){
                                        buttons[index] = AnnotState.inactive;
                                        lines.removeAt(index);
                                      });
                                      oldPath = '';
                                      func();
                                    }
                                  }),
                                )*/
                                    ],
                                  )
                              )
                          )
                      )
                  );
                }
            )).toList() : [];
            return !snapshot.hasData
                ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                : scrollDirection == Axis.horizontal ? ListView(
                shrinkWrap: true,
                physics: const ScrollPhysics(),
                scrollDirection: scrollDirection!,
                controller: scrollController,
                children: children
            ) : SingleChildScrollView(
                controller: scrollController,
                physics:  const ScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                )
            );
          });
    }

  }

  String commentBody = '';

  ///диалог ввода комментария в аннотацию
  Future<bool>addCommentDialog(context) async {
    bool result = true;
    TextEditingController controller = TextEditingController();
    FocusNode myFocusNode1 = FocusNode();
    OutlineInputBorder border = const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(7.0)),
        borderSide: BorderSide(color: Color(0xFF1D2830), width: 2));
    BoxConstraints constraints = const BoxConstraints(minWidth: 40.0, minHeight: 40.0, maxWidth: 40.0, maxHeight: 40.0);

    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                void _requestFocus1(){
                  setState(() {
                    FocusScope.of(context).requestFocus(myFocusNode1);
                  });
                }
                return AlertDialog(

                  backgroundColor: Colors.transparent,
                  elevation: 0.0,
                  scrollable: true,
                  contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  insetPadding: const EdgeInsets.all(10),
                  content: Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    width: 300,
                    height: 270,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(11.0),),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                              margin: const EdgeInsets.fromLTRB(0,0,0,0),
                              padding: const EdgeInsets.fromLTRB(0,0,0,0),
                              alignment: Alignment.topCenter,
                              width: MediaQuery.of(context).size.width - 40,
                              height: 200,
                              child:TextFormField(
                                autofocus: true,
                                maxLines: 15, minLines: 15, expands: false,
                                maxLength: 1000,
                                onTap: _requestFocus1,
                                focusNode: myFocusNode1,
                                textAlign: TextAlign.left,
                                enabled: true,
                                //style: inputTextStyle,
                                keyboardType: TextInputType.streetAddress,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(
                                      left: 15,
                                      top: 10,
                                      bottom: 10
                                  ),
                                  counter: SizedBox.shrink(),
                                  //hintStyle: inputHintTextStyle,
                                  hintText: "Комментарий",
                                  border: border,
                                  focusedBorder: border,
                                  enabledBorder: border,
                                  errorBorder: border,
                                  labelText: 'Комментарий',
                                  labelStyle: TextStyle(fontSize: 15.0, color: myFocusNode1.hasFocus ? const Color(0xFF1D2830) : Colors.black,fontFamily: 'Inter'),
                                ),
                                onChanged: (_){setState(() {
                                  //postalEmpty = false;
                                });},
                                //validator: (value) => postalEmpty ? 'Поле адрес не должно быть пустым' : null,
                                autovalidateMode: AutovalidateMode.always,
                                controller: controller,
                              )),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RawMaterialButton(
                                constraints: constraints,
                                onPressed: (){
                                  commentBody = '';
                                  result = false;
                                  Navigator.of(context).pop();
                                },
                                elevation: 2.0,
                                fillColor: Colors.indigo,
                                padding: const EdgeInsets.all(5.0),
                                shape: const CircleBorder(),
                                child: const Icon(CupertinoIcons.clear, color: Colors.white,),
                              ),
                              RawMaterialButton(
                                constraints: constraints,
                                onPressed: (){
                                  commentBody = controller.text;
                                  result = true;
                                  Navigator.of(context).pop();
                                },
                                elevation: 2.0,
                                fillColor: Colors.indigo,
                                padding: const EdgeInsets.all(5.0),
                                shape: const CircleBorder(),
                                child: const Icon(CupertinoIcons.check_mark, color: Colors.white,),
                              )
                            ],
                          )
                        ]),
                  ),
                );
              }
          );
        }
    ).then((value) => null);
    return result;
  }


}


extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = Set();
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}