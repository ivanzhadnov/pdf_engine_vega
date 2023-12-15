import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pdf_engine_vega/view/widgets/annot_eraser.dart';
import 'package:pdfium_bindings/pdfium_bindings.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:system_info2/system_info2.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../edit/annot_buttons.dart';
import '../edit/annot_painter.dart';
import '../edit/annotation_class.dart';

import '../edit/bookmark_class.dart';
import '../edit/line_class.dart';
import '../util/current_system_info.dart';
import '../util/piont_in_circle.dart';
import 'extract_text/syficion_text_extract.dart';

///бинарники бибилотек https://github.com/bblanchon/pdfium-binaries
///обработка загрузки и конвертации PDF файла под разные ОС и последующее отображение на экране пользователя
///обработка отображения и добавления аннотирования в документ
class LoadPdf{

  LoadPdf(){setPdfium();}

  PdfiumWrap? pdfium;
  ///set pdfium
  Future<bool>setPdfium()async{

    ///получаем данные об установленой ОС, архитектуре процессора, разрядности процессора
    //CurrentSystemInformation? sysInfo = Platform.isIOS || Platform.isWindows ? null : CurrentSystemInformation();

    try{
      if(!Platform.isMacOS)pdfium!.dispose();
    }catch(e){}

    String libraryPath = '';
    final directory = await getApplicationDocumentsDirectory();
    if(Platform.isAndroid){
      String libAsset = 'assets/libpdf/libpdfium_android.so';
      // if(sysInfo!.kernelBitness == 32){
      //   if(sysInfo.kernelArchitecture == ProcessorArchitecture.x86){
      //     libAsset = 'assets/libpdf/libpdfium_android_32_x86.so';
      //   }else{
      //     libAsset = 'assets/libpdf/libpdfium_android_32.so';
      //   }

      }
      final String localPath = directory.path;
      File file = File('$localPath/libpdfium_android.so');
      bool exist = await file.exists();
      if(!exist){
        final asset = await rootBundle.load(libAsset);
        final buffer = asset.buffer;
        await file.writeAsBytes(buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes));
      }
      libraryPath = file.path;
    }
    else if(Platform.isMacOS){
      libraryPath = 'libpdfium.dylib';
    }
    ///TODO привязать библиотеку к иос
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
    if(!Platform.isIOS)pdfium = PdfiumWrap(libraryPath: libraryPath);
    return true;
  }

  ///получить массив со страницами в зависиомтси от ОС
  ///юзаем только чтоб показать лицензию
  ///TODO убрать
  Future<List<Image>>getPagesListImage({required String pathPdf, int ration = 1, String backgroundColor = '#FF0B1730'})async {
    List<Image> result = [];
    if(Platform.isIOS){
      result = await loadAssetAsListIOS(pathPdf: pathPdf, ration: ration, backgroundColor: backgroundColor);
    }else{
      result = await loadAssetAsList(pathPdf: pathPdf, ration: ration, backgroundColor: backgroundColor);
    }
    return result;
  }

  ///получить количество страниц в документе
  Future<int>getPageCount({required String pathPdf,})async{
    return await syficionGetPageCount(pathPdf: pathPdf);
  }

  String pathDocument = '';

  ///текст строками TextLines
  List<List<sf.TextLine>> textLines = [];

  ///результат поиска текста в документе
  List<sf.MatchedItem> findedFragments = [];



  ///получить байты Используется в 4-х местах в проекте
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
  ///используется только для показа лицензии
  ///TODO убрать
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
  ///используется только для показа лицензии
  ///TODO убрать
  Future<List<Image>> loadAssetAsList({required String pathPdf, int ration = 1, String backgroundColor = '#FFFFFFFF'})async{
    List<Image> result = [];
    final directory = await getApplicationDocumentsDirectory();
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
      ///получаем исходные размеры документа, чтоб потом подстраивать рисование
      bornDocSize = await syficionGrtSize(pathPdf: pathPdf, page: i);
      aspectRatioDoc = bornDocSize.aspectRatio;
      screenWidth = bornDocSize.width;
      screenHeight = bornDocSize.width / aspectRatioDoc;
      aspectCoefX = bornDocSize.width / bornDocSize.width;
      aspectCoefY = screenHeight / bornDocSize.height;

      String fileName = 'render';
      imageCache.evict(FileImage(File('${directory.path}${Platform.pathSeparator}$fileName$i.jpg')), includeLive: true);
      imageCache.clear();
      imageCache.clearLiveImages();
      document.loadPage(i)
      //.renderPageAsBytes(300, 400, /*backgroundColor:  int.parse(backgroundColor, radix: 16),*/ flags: 1);
          .savePageAsJpg('${directory.path}${Platform.pathSeparator}$fileName$i.jpg', qualityJpg: 100, flags: 1, width: screenWidth.toInt(), height: screenHeight.toInt(),)
          .closePage();
      result.add(
          !Platform.isAndroid && !Platform.isWindows ? Image.asset('${directory.path}${Platform.pathSeparator}$fileName$i.jpg')
              : Image.file(File('${directory.path}${Platform.pathSeparator}$fileName$i.jpg'))
      );
    }
    //document.closeDocument().dispose();
    return result;
  }



  Size bornDocSize = const Size(0,0);
  double aspectRatioDoc = 1;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double aspectCoefX = 1;
  double aspectCoefY = 1;


  ///загрузка файла PDF целиком
  Future<List<Uint8List>> loadAssetAll({required String pathPdf,List<AnnotationItem>? annotations, List<BookMarkPDF>? bookmarks = const [], double? width, double? height}) async {
    String _path = pathPdf;
    ///получаем исходные размеры документа, чтоб потом подстраивать рисование
    bornDocSize = await syficionGrtSize(pathPdf: pathPdf);
    aspectRatioDoc = bornDocSize.aspectRatio;
    width ??= bornDocSize.width;
    height ??= bornDocSize.height;
    screenWidth = width;
    screenHeight = width / aspectRatioDoc;
    aspectCoefX = width / bornDocSize.width;
    aspectCoefY = screenHeight / bornDocSize.height;

    ///добавляем аннотации если они есть или были нарисованы
    _path =  await syficionAddAnnotation(pathPdf: pathPdf, annotations: annotations, bookmarks: bookmarks);
    List<Uint8List> filesPaths = [];
    final directory = await getApplicationDocumentsDirectory();
    String fileName = 'render';
    int pageCount = await syficionGetPageCount(pathPdf:  _path);
    if(Platform.isIOS){
      PdfDocument pdfDocument = await PdfDocument.openFile(_path);
      for (int i = 1; i <= pageCount; i++) {
        final pdfPage = await pdfDocument.getPage(i);
        final pdfWidth = screenWidth * 2;
        final pdfHeight = screenHeight * 2;
        final image = await pdfPage.render(
          width: pdfWidth,
          height: pdfHeight,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFFFF',
          quality: 100,
        );
        final bytes = image!.bytes;
        filesPaths.add(bytes);
      }
      await pdfDocument.close();
    }
    else{

      late Uint8List bytes;
      ///загрузка из ассета, но нам может понадобиться загрузка из локального хранилища
      try{
        bytes = (await rootBundle.load(_path)).buffer.asUint8List();
      }catch(e){
        bytes = (File(_path).readAsBytesSync());
      }
      ///получить количество страниц
      final document = pdfium!.loadDocumentFromBytes(bytes);
      ///циклом собрать массив отрендеренных страниц для отображения

      for(int i = 0; i < pageCount; i++){
        document.loadPage(i).
            savePageAsJpg('${directory.path}${Platform.pathSeparator}$fileName$i.jpg', qualityJpg: 100, flags: 1, width: screenWidth.toInt(), height: screenHeight.toInt(),)
            .closePage();
        final bytes = await File('${directory.path}${Platform.pathSeparator}$fileName$i.jpg').readAsBytes();
        filesPaths.add(bytes);
      }
    }
    return filesPaths;
  }

  List<List<DrawLineItem>> lines = [];
  ///установщик оси У для выделения текста
  double yLine = -1;


  ///массив для опредделения размеров окна с отображаемой страницей
  List<GlobalKey> globalKeys = [];

  String oldPath = '';
  List<Uint8List> oldListPaths = [];


  ///индикация активной страницы и перелистывание страниц
  int visiblyPage = 0;
  ScrollController scrollController = ScrollController();

  ///возвращаем уже сохраненные картинки с ПДФ для блокировки нежелательной перерисовки
  Future<List<Uint8List>> returnOldList()async{
    return oldListPaths;
  }


  ///обрабатываем нажатие по скролл контроллеру
  changePage(int page, setState){
    if(oldListPaths.length > 1){
      scrollController.jumpTo((screenHeight + 10) * page);
      setState();
    }

  }

  ///переменные для работы с ластиком
  double eraseRadius = 10.0;
  Offset erasePosition = const Offset(-100, -100);
  List<List<List<Offset>>> erasePositions = [];
  ///формируем разорванные ластиком массивы, после добавим их в основной массив
  List<DrawLineItem> brokenLists = [];


  String searchTextString = '';



  ///Загружаем в ListView документ целиком
  Widget child({
    ///путь к файлу PDF, может быть как asset так и из хранилища документов
    required String pathPdf,
    ///массив аннотаций полученых с сервера
    List<AnnotationItem>? annotations = const [],
    ///требуемая к выполнению внешняя функция
    dynamic func,
    ///направление прокрутки при просмотре файла
    Axis? scrollDirection = Axis.vertical,
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
    imageCache.clear();
    imageCache.clearLiveImages();
    pathDocument = pathPdf;
    ///обработка нажатия на страницу
    void onTap(int index)async{
      ///уточняем номер текущей страницы
      visiblyPage = index;
      try{
        func();
      }catch(e){}
    }
    ///обработка начала рисования
    void onPanStart(v, int index, setState){
      if(mode == AnnotState.selectText || mode == AnnotState.freeForm){
        lines[index].add(DrawLineItem(subject: mode.name));
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
        if(lines[index].last.line.isNotEmpty){
          final temp = lines[index].last.line;
          lines[index].last.line = [temp.first, temp.last];
          setState((){});
          try{
            func();
          }catch(e){}
        }
      }else if(mode == AnnotState.erase){
        erasePositions[index] = [];
      }
    }
    ///обработка рисования
    void onPanUpdate(DragUpdateDetails details, int index, setState) {
      Offset current = Offset(details.localPosition.dx, details.localPosition.dy);
      if(mode == AnnotState.selectText || mode == AnnotState.freeForm){
        final RenderObject? renderBoxRed = globalKeys[index].currentContext!.findRenderObject();
        final maxHeight = renderBoxRed!.paintBounds.height;
        final maxWidth = renderBoxRed.paintBounds.width;
        double x = 0;
        double y = 0;
        if(current.dx < maxWidth && current.dx > 0){
          x = current.dx;
        }else{
          x = current.dx > 0 ? maxWidth - 10 : 0;
        }
        if(current.dy < maxHeight && current.dy > 0){
          y = current.dy;
        }else{
          y = current.dy > 0 ? maxHeight - 10 : 0;
        }
        if(mode == AnnotState.selectText){
          if(textLines[visiblyPage].isNotEmpty){
            final calculated = textLines[visiblyPage].where((el) => current.dy.clamp(el.bounds.top * aspectCoefY, el.bounds.bottom * aspectCoefY) == current.dy).toList();
            ///рисуем прямую при условии, что есть текст
            if(calculated.isNotEmpty){
              if(yLine == -1){
                yLine = calculated.map((e) => e.bounds.centerLeft.dy * aspectCoefY).last;
              }
              print(calculated.map((e) => e.text).last);
              lines[index].last.text = calculated.map((e) => e.text).last;
              lines[index].last.line.add(Offset(x, yLine ));
            }
          }
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
        for(int i = 0; i < lines[index].length; i++) {
          ///массив для хранения точек подлежащих стиранию
          List pointsToDelete = lines[index][i].line.where((point) =>
              belongsToCircle(x: point.dx,
                  y: point.dy,
                  centerX: erasePosition.dx,
                  centerY: erasePosition.dy,
                  radius: eraseRadius)).toList();
          if(pointsToDelete.isNotEmpty){
            ///края по которым будем рвать массив линии на два новых массива
            Offset pointsToGap = pointsToDelete.last;
            pointsToDelete.removeLast();
            lines[index][i].line.removeWhere((point) => pointsToDelete.contains(point));
            int splitIndex = lines[index][i].line.indexWhere((element) => element == pointsToGap);
            final tmpFirst = DrawLineItem(subject: lines[index][i].subject)..color = lines[index][i].color..thickness=lines[index][i].thickness..undoLine=lines[index][i].undoLine..undoColor=lines[index][i].undoColor..undoThickness=lines[index][i].undoThickness;
            final tmpSecond = DrawLineItem(subject: lines[index][i].subject)..color = lines[index][i].color..thickness=lines[index][i].thickness..undoLine=lines[index][i].undoLine..undoColor=lines[index][i].undoColor..undoThickness=lines[index][i].undoThickness;
            tmpFirst.line = lines[index][i].line.map((e) => e).toList().sublist(0, splitIndex);
            tmpSecond.line = lines[index][i].line.map((e) => e).toList().sublist(splitIndex);
            brokenLists..add(tmpFirst)..add(tmpSecond);
          }else{
            brokenLists.add(lines[index][i]);
          }
        }

        lines[index] = brokenLists;
        brokenLists = [];
        setState((){});
      }
    }



    ///обработка прокрутки страниц и установка номера активной страницы
    void onVisibilityChanged(VisibilityInfo info) {
      visiblyPage = int.parse(info.key.toString().replaceAll('[<\'', '').replaceAll('\'>]', ''));
      try{
        func();
      }catch(e){}
    }

    return FutureBuilder<List<Uint8List>>(
        future: oldPath == pathPdf ? returnOldList()
            : loadAssetAll(pathPdf: pathPdf, annotations: annotations, bookmarks: bookmarks, width: width, height: height),
        builder: (context, snapshot) {
          if(snapshot.hasData && oldPath != pathPdf){
            ///блокируем перерисовки
            lines = List.generate(snapshot.data!.length, (_) => [DrawLineItem(subject: mode.name)]);
            erasePositions = List.generate(snapshot.data!.length, (_) => []);
            globalKeys = List.generate(snapshot.data!.length, (_) => GlobalKey());
            oldListPaths = snapshot.data!;
            oldPath = pathPdf;

          }
          List<Widget> children = snapshot.hasData && oldListPaths.isNotEmpty ? snapshot.data!.map((item) => StatefulBuilder(
              builder: (BuildContext context, StateSetter setState){
                ///номер страницы
                int index = snapshot.data!.indexWhere((e) => e == item);
                return Center(
                    child:GestureDetector(
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
                                  //color: Colors.red.withOpacity(0.5),
                                    width: screenWidth,
                                    key: globalKeys[index],
                                    margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                    child: Stack(
                                      children: [
                                        ///поворт блока надо совместить с нарисованными линиями
                                        Image.memory(
                                          item,
                                          width: screenWidth,
                                          height: screenHeight,
                                          fit: BoxFit.fitWidth,
                                        ),
                                        ///рисуем выделения найденого текста
                                        ...findedFragments.where((el) => el.pageIndex == index).toList().map((e) => Positioned(
                                            top:e.bounds.top * aspectCoefY,
                                            left: e.bounds.left * aspectCoefX,
                                            child: Container(
                                              color: Colors.yellow.withOpacity(0.7),
                                              width: e.bounds.width * aspectCoefY,
                                              height: e.bounds.height * aspectCoefX,
                                            ))).toList(),
                                        ///показываем, что есть закладка
                                        if(bookmarks != null)
                                          ...bookmarks.where((e) => e.page == index).toList().map((v) => Positioned(
                                            left: v.offset.dx,
                                            top: v.offset.dy,
                                            child: SizedBox(
                                                width: 30,
                                                height: 30,
                                                child: Image.asset('assets/pdf_buttons/bookmark_active.png')
                                            ),
                                          )).toList(),
                                        ///рисуем нарисованную аннотацию как затычку
                                        ...lines[index].map((e)=>FingerPaint(line:  e.line, mode: mode == AnnotState.erase ? AnnotState.freeForm : mode, color: e.color, thickness: e.thickness, )).toList(),

                                        ...annotations!.where((element) =>
                                        element.page == index)
                                            .toList().map((e){
                                          e.aspectCoefX = aspectCoefX;
                                          e.aspectCoefY = aspectCoefY;
                                          return FingerPaint(line: e.points.map((p) => Offset(p.x * aspectCoefX, p.y * aspectCoefY)).toList(), mode: e.subject == 'selectText' ? AnnotState.selectText : AnnotState.freeForm, color: Color(e.color!.toInt())      , thickness: e.border!.width, );
                                        }).toList(),
                                        ///интегрируется виджет области аннотации
                                        ...annotations.where((element) =>
                                        element.page == index)
                                            .toList().map((e){
                                          e.aspectCoefX = aspectCoefX;
                                          e.aspectCoefY = aspectCoefY;
                                          return e.tapChild;
                                        }).toList(),
                                        ///указатель ластика
                                        if(mode == AnnotState.erase && index == visiblyPage) AnnotEraser(eraseRadius: eraseRadius, erasePosition: erasePosition,),
                                      ],
                                    )
                                )
                            )
                        )
                    )
                );
              }
          )).toList() : [];
          return !snapshot.hasData && oldListPaths.isEmpty
              ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
              : ListView(
              //itemExtent:3,
              cacheExtent: 3,
              shrinkWrap: true,
              physics: const ScrollPhysics(),
              scrollDirection: scrollDirection!,
              controller: scrollController,
              children: children
          );
        });
    //}

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