import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:async/async.dart';

import 'package:path/path.dart' as path;
import 'package:pdf_engine_vega/view/widgets/annot_eraser.dart';
import 'package:pdfium_bindings/pdfium_bindings.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pinch_zoom_release_unzoom/pinch_zoom_release_unzoom.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../edit/annot_buttons.dart';
import '../edit/annot_painter.dart';
import '../edit/annotation_class.dart';

import '../edit/bookmark_class.dart';
import '../edit/line_class.dart';
import '../util/current_system_info.dart';
import '../util/mached_item_class.dart';
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
    CurrentSystemInformation? sysInfo;
    if (!(Platform.isIOS || Platform.isWindows)) sysInfo = CurrentSystemInformation();

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
      //
      // }
      final String localPath = directory.path;
      File file = File('$localPath/libpdfium_android.so');
      bool exist = await file.exists();
      if(!exist){
        print('файла библиотеки нет, поэтому копируем его из ассет');
        final asset = await rootBundle.load(libAsset);
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
      libraryPath = path.join(Directory.current.path, 'pdfium_win.dll');
    }
    else if(Platform.isLinux){
      libraryPath = path.join(Directory.current.path, 'libpdfium.so');
    }
    if(!Platform.isIOS)pdfium = PdfiumWrap(libraryPath: libraryPath);
    return true;
  }

  ///получить количество страниц в документе
  Future<int>getPageCount({required String pathPdf,})async{
    return await getPagesCount(pathPdf: pathPdf);
  }

  String pathDocument = '';

  ///текст строками TextLines
  List<List<sf.TextLine>> textLines = [];

  ///результат поиска текста в документе
  List<MatchedItemMy> findedFragments = [];

  Size bornDocSize = const Size(0,0);
  double aspectRatioDoc = 1;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double aspectCoefX = 1;
  double aspectCoefY = 1;
  bool loadComplite = false;

  PdfiumWrap? document;
  ///загрузка файла PDF целиком
  Future<List<Uint8List>> loadAssetAll({
    required String pathPdf,
    List<AnnotationItem>? annotations,
    List<BookMarkPDF>? bookmarks = const [],
    double? width,
    double? height,
    int? page,
    int? zoom,
    String? color,
  }) async {
    //print('загрузили по новой $page zoom $zoom');
    List<Uint8List> filesPaths = [];
    String _path = pathPdf;

      ///получаем исходные размеры документа, чтоб потом подстраивать рисование
      bornDocSize = await getPageSize(pathPdf: pathPdf);
      aspectRatioDoc = bornDocSize.aspectRatio;
      width = bornDocSize.width * (zoom ?? 1);
      height = bornDocSize.height * (zoom ?? 1);

      screenWidth = width;
      screenHeight = height;
      aspectCoefX = width / bornDocSize.width;
      aspectCoefY = height / bornDocSize.height;
      ///добавляем аннотации если они есть или были нарисованы
      final directory = await getApplicationDocumentsDirectory();
      String fileName = 'render${zoom != null && zoom != 1 ? 'zoom' : ''}';
      int pageCount = page != null ? 0 : await getPageCount(pathPdf:  _path);

      if(Platform.isIOS || Platform.isAndroid){
        _path =  await syficionAddAnnotation(pathPdf: pathPdf, annotations: annotations, bookmarks: bookmarks, page: page, addContent: false);
        loadComplite = true;
        PdfDocument pdfDocument = await PdfDocument.openFile(_path);
        if(page == null){
          for (int i = 1; i <= pageCount; i++) {
            final pdfPage = await pdfDocument.getPage(i);
            final pdfWidth = screenWidth;
            final pdfHeight = screenHeight;
            final image = await pdfPage.render(
              width: pdfWidth,
              height: pdfHeight,
              format: PdfPageImageFormat.jpeg,
              backgroundColor: color ?? '#FFFFFFFF',
              quality: 100,
            );
            if(Platform.isAndroid) pdfPage.close();
            final _bytes = image!.bytes;
            filesPaths.add(_bytes);
          }
        }else{
          final pdfPage = await pdfDocument.getPage(page + 1);
          final pdfWidth = screenWidth;
          final pdfHeight = screenHeight;
          final image = await pdfPage.render(
            width: pdfWidth,
            height: pdfHeight,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: color ?? '#FFFFFFFF',
            quality: 100,
          );
          if(Platform.isAndroid) pdfPage.close();
          final bytes = image!.bytes;
          filesPaths.add(bytes);
        }

        await pdfDocument.close();
      }
      else{
        if(document == null){
          _path =  await syficionAddAnnotation(pathPdf: pathPdf, annotations: annotations, bookmarks: bookmarks, addContent: false);
          loadComplite = true;
          late Uint8List bytes;
          ///загрузка из ассета, но нам может понадобиться загрузка из локального хранилища
          try{
            bytes = (await rootBundle.load(_path)).buffer.asUint8List();
          }catch(e){
            bytes = (File(_path).readAsBytesSync());
          }
          ///получить количество страниц
          document = pdfium!.loadDocumentFromBytes(bytes);
        }


        ///циклом собрать массив отрендеренных страниц для отображения
        if(page == null){
          //print('$pageCount');
          List<int> rotation = await getPageRotation(pathPdf: pathPdf,);

          for(int i = 0; i < pageCount; i++){
            int realWidth = 0;
            int realHeight = 0;

            Size size = await getPageSize(pathPdf: pathPdf, page: i);


            if(rotation[i] == 0 || rotation[i] == 2){
              realWidth = (size.width * (zoom ?? 1)).toInt();
              realHeight = (size.height * (zoom ?? 1)).toInt();
            }else{
              realWidth = rotation[i] == 0 || rotation[i] == 2 ? screenWidth.toInt() : screenHeight.toInt();
              realHeight = rotation[i] != 0 && rotation[i] != 2 ? screenWidth.toInt() : screenHeight.toInt();
            }
            document!.loadPage(i).
            savePageAsJpg('${directory.path}${Platform.pathSeparator}$fileName$i.jpg', qualityJpg: 100, flags: 0, width: realWidth, height: realHeight, backgroundColor: int.parse((color ?? '#FFFFFFFF').replaceAll('#', '0x')))
                .closePage();
            final _bytes = await File('${directory.path}${Platform.pathSeparator}$fileName$i.jpg').readAsBytes();
            filesPaths.add(_bytes);
          }
        }
        else{
          List<int> rotation = await getPageRotation(pathPdf: pathPdf, page: page);
          Size size = await getPageSize(pathPdf: pathPdf, page: page);
          int realWidth = 0;
          int realHeight = 0;
          if(rotation.first == 0 || rotation.first == 2){
            realWidth = (size.width * (zoom ?? 1)).toInt();
            realHeight = (size.height * (zoom ?? 1)).toInt();
          }else{
            realWidth = rotation.first == 0 || rotation.first == 2 ? screenWidth.toInt() : screenHeight.toInt();
            realHeight = rotation.first != 0 && rotation.first != 2 ? screenWidth.toInt() : screenHeight.toInt();
          }

          document!.loadPage(page).
          savePageAsJpg('${directory.path}${Platform.pathSeparator}$fileName$page.jpg', qualityJpg: 100, flags: 0, width: realWidth, height: realHeight,).closePage();
          final _bytes = File('${directory.path}${Platform.pathSeparator}$fileName$page.jpg').readAsBytesSync();
          filesPaths[page]=_bytes;
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
  String selectedUuid = '';



  ///индикация активной страницы и перелистывание страниц
  int visiblyPage = 0;
  ScrollController scrollController = ScrollController();

  ///переменные для работы с ластиком
  double eraseRadius = 10.0;
  Offset erasePosition = const Offset(-100, -100);
  List<List<List<Offset>>> erasePositions = [];
  ///формируем разорванные ластиком массивы, после добавим их в основной массив
  List<DrawLineItem> brokenLists = [];
  String searchTextString = '';

RestartableTimer _tapTimer = RestartableTimer(const Duration(seconds: 1), () {});
bool _brakeChangePage = false;
int? _page;

  ///обрабатываем нажатие по скролл контроллеру
  ///нужно дождаться пока перестанут тыкать и перейти на нужную страницу
  changePage(int page, setState){
if(_brakeChangePage == true){
  print('пропустили нажатие');
  _tapTimer.reset();
  visiblyPage = page.abs();
  _page =  page.abs();
  setState();
}else{
  print('отработали нажатие');
  _brakeChangePage = true;
  _tapTimer = RestartableTimer(const Duration(milliseconds: 300), () {
    _brakeChangePage = false;
    if(oldListPaths.length > 1){
      scrollController.jumpTo(0);
      double counterHeight = 0;
      int _counter = _page ?? page.abs();
      for(int i = 0; i < _counter; i++){
        try{
          final RenderObject? renderBoxRed = globalKeys[i].currentContext!.findRenderObject();
          counterHeight += renderBoxRed!.paintBounds.height;
        }catch(e){
          counterHeight += screenHeight;
        }
      }
      //scrollController.jumpTo(counterHeight - (visiblyPage < page ? 70 : 0));
      scrollController.jumpTo(counterHeight);
      visiblyPage =  _counter;
      _page = null;
      setState();
    }

  });
}

  }

  int count = 0;
  Future<List<Uint8List>>retutnBytes(int index, zoom)async{
   // print('загрузили сохраненную страницу $index length ${oldListPaths[index].lengthInBytes}');
    return [oldListPaths[index]];
  }

  Future<int>returnCount()async{
    return count;
  }

  Offset startSelectTextPoint = const Offset(0.0,0.0);
  Offset endtSelectTextPoint = const Offset(0.0,0.0);
  List<List<Rect>> selectedFragments = [];

  Widget childs({
    ///путь к файлу PDF, может быть как asset так и из хранилища документов
    required String pathPdf,
    ///направление прокрутки при просмотре файла
    Axis? scrollDirection = Axis.vertical,
    ///массив аннотаций полученых с сервера
    List<AnnotationItem>? annotations = const [],
    ///номера страниц на которых установлены закладки
    List<BookMarkPDF>? bookmarks,
    ///размеры экрана
    double? width,
    double? height,
    int? zoom,
    ///поворот документа
    int rotation = 0,
    ///получаем режим рисования из вне
    required AnnotState mode,
    ///требуемая к выполнению внешняя функция
    dynamic func,
  }){

    pathDocument = pathPdf;
    ///обработка нажатия на страницу
    void onTap(int index)async{
      ///уточняем номер текущей страницы
      visiblyPage = index;
      selectedUuid = '';
      try{
        func();
      }catch(e){}
    }
    ///обработка начала рисования
    void onPanStart(DragStartDetails v, int index, setState){
      ///зафиксировали начало выделения текста
      startSelectTextPoint = v.localPosition;
        if(mode == AnnotState.erase){
        erasePositions[index].add([]);
        setState((){});
      }
    }
    ///обработка завершения рисования линии и подготовка новой линии
    void onPanEnd(v, int index, setState){
      ///формируем ровную и без лишних точек линию выделения текста, так эстетичнее и уменьшается нагрузка
        if(mode == AnnotState.erase){
        erasePositions[index] = [];
      }else if(mode == AnnotState.selectText || mode == AnnotState.freeForm){
        if(lines[index].isNotEmpty){
          final color = lines[index].last.color;
          final thicknes = lines[index].last.thickness;
          lines[index].add(DrawLineItem(subject: mode.name, uuid: Uuid().v4()));
          lines[index].last.color = color;
          lines[index].last.thickness = thicknes;
        }else{
          lines[index].add(DrawLineItem(subject: mode.name, uuid: Uuid().v4()));
        }

        yLine = -1;
        setState((){});
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
          endtSelectTextPoint = current;
          if(textLines[visiblyPage].isNotEmpty && lines[index].isNotEmpty){
            lines[index].last.subject = 'selectText';
            lines[index].last.line = [];
           ///создаем массив из текслиний которые между началом и концом курсора по высоте
            Offset newstartSelectTextPoint = const Offset(0.0,0.0);
            Offset newendtSelectTextPoint = const Offset(0.0,0.0);
            if(startSelectTextPoint.dy < endtSelectTextPoint.dy){
              newstartSelectTextPoint = startSelectTextPoint;
              newendtSelectTextPoint = endtSelectTextPoint;
            }else{
              newstartSelectTextPoint = endtSelectTextPoint;
              newendtSelectTextPoint = startSelectTextPoint;
            }
            final filterdLines = [];

            for(int i = 0; i < textLines[visiblyPage].length; i++){
              if(textLines[visiblyPage][i].bounds.bottom >= newstartSelectTextPoint.dy
              && textLines[visiblyPage][i].bounds.top <= newendtSelectTextPoint.dy){
                filterdLines.add(textLines[visiblyPage][i]);
              }
            }

            if(filterdLines.isNotEmpty){
              //String result = '';
              selectedFragments[visiblyPage] = [];
              for(int i =0; i < filterdLines.length; i++){
               // if(i%2==0){
                  ///выделяем с лева на право
                  for(int ii =0; ii < filterdLines[i].wordCollection.length; ii++){
                    if(i == 0 && filterdLines[i].wordCollection[ii].bounds.left >= newstartSelectTextPoint.dx){
                      if( !selectedFragments[visiblyPage].contains(filterdLines[i].wordCollection[ii - 1].bounds)) selectedFragments[visiblyPage].add(filterdLines[i].wordCollection[ii-1].bounds);
                     if( !selectedFragments[visiblyPage].contains(filterdLines[i].wordCollection[ii].bounds)) selectedFragments[visiblyPage].add(filterdLines[i].wordCollection[ii].bounds);
                      //result += filterdLines[i].wordCollection[ii].text;
                    }else if( i == filterdLines.length - 1 && filterdLines[i].wordCollection[ii].bounds.right <= newendtSelectTextPoint.dx){
                      if( !selectedFragments[visiblyPage].contains(filterdLines[i].wordCollection[ii].bounds))selectedFragments[visiblyPage].add(filterdLines[i].wordCollection[ii].bounds);
                      //result += filterdLines[i].wordCollection[ii].text;
                    }else if(i != 0 && i != filterdLines.length - 1){
                      if( !selectedFragments[visiblyPage].contains(filterdLines[i].wordCollection[ii].bounds))selectedFragments[visiblyPage].add(filterdLines[i].wordCollection[ii].bounds);
                      //result += filterdLines[i].wordCollection[ii].text;
                    }

                  }

              }
              //lines[index].last.text = result;
              for(int i = 0; i < selectedFragments[visiblyPage].length; i++){
                if(i == 0){
                  lines[index].last.line.add(selectedFragments[visiblyPage][i].bottomLeft);
                  lines[index].last.line.add(selectedFragments[visiblyPage][i].topLeft);
                }
                ///находим координаты углов конца строки и координаты углов начала следующей строки
                else if(selectedFragments[visiblyPage][i].top != selectedFragments[visiblyPage][i - 1].top){
                  lines[index].last.line.add(selectedFragments[visiblyPage][i - 1].topRight);
                  lines[index].last.line.add(selectedFragments[visiblyPage][i - 1].bottomRight);
                  lines[index].last.line.add(Offset(selectedFragments[visiblyPage][i -1].right, selectedFragments[visiblyPage][i].top));
                }
                ///печатаем край последней строки
                else if(i == selectedFragments[visiblyPage].length -1){
                  lines[index].last.line.add(selectedFragments[visiblyPage][i].topRight);
                  lines[index].last.line.add(selectedFragments[visiblyPage][i].bottomRight);
                }
              }

              for(int i = selectedFragments[visiblyPage].length -1; i > 0; i--){
                if(i == selectedFragments[visiblyPage].length -1){}
                ///находим координаты углов конца строки и координаты углов начала следующей строки
                else if(selectedFragments[visiblyPage][i].top != selectedFragments[visiblyPage][i - 1].top){
                  lines[index].last.line.add(selectedFragments[visiblyPage][i].bottomLeft);
                  lines[index].last.line.add(selectedFragments[visiblyPage][i].topLeft);
                }
                ///печатаем край последней строки
                else if(i == 0){}
              }
              lines[index].last.line.add(Offset(selectedFragments[visiblyPage][0].left, lines[index].last.line.last.dy ));
              lines[index].last.line.add(selectedFragments[visiblyPage][0].bottomLeft,);
            }

          }
        }else{
          if(lines[index].isEmpty){
            lines[index].add(DrawLineItem(subject: mode.name, uuid: Uuid().v4()));
          }
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
                  radius: eraseRadius) && lines[index][i].subject != "selectText").toList();
          if(pointsToDelete.isNotEmpty){
            ///края по которым будем рвать массив линии на два новых массива
            Offset pointsToGap = pointsToDelete.last;
            pointsToDelete.removeLast();
            lines[index][i].line.removeWhere((point) => pointsToDelete.contains(point));
            int splitIndex = lines[index][i].line.indexWhere((element) => element == pointsToGap);
            final tmpFirst = DrawLineItem(uuid: lines[index][i].uuid, subject: lines[index][i].subject)..color = lines[index][i].color..thickness=lines[index][i].thickness..undoLine=lines[index][i].undoLine..undoColor=lines[index][i].undoColor..undoThickness=lines[index][i].undoThickness;
            final tmpSecond = DrawLineItem(uuid: lines[index][i].uuid, subject: lines[index][i].subject)..color = lines[index][i].color..thickness=lines[index][i].thickness..undoLine=lines[index][i].undoLine..undoColor=lines[index][i].undoColor..undoThickness=lines[index][i].undoThickness;
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
        if((info.visibleFraction > 0.51 || (zoom ?? 1) > 1) && _brakeChangePage == false){
          visiblyPage = int.parse(info.key.toString().replaceAll('[<\'', '').replaceAll('\'>]', ''));
          if(visiblyPage == 0){
            try{
            func();
            }catch(e){}
          }

        }
    }

    bool reload = false;
    bool blockScroll = false;

    ///определяем количество страниц в документе
    return FutureBuilder<int>(
        future: count == 0 ? getPageCount(pathPdf: pathPdf) : returnCount(),
        builder: (context, snapshot) {
          if(snapshot.hasData && count == 0){
            reload = true;
            count = snapshot.data ?? 0;
            if(count > 0){
              lines = List.generate(count, (_) => []);
              erasePositions = List.generate(count, (_) => []);
              globalKeys = List.generate(count, (_) => GlobalKey());
              oldListPaths = List.generate(count, (_) => Uint8List(0));
              selectedFragments = List.generate(count, (_) => []);
            }
          }


          List<Widget> _children = List.generate(count, (index) => index == 0 || visiblyPage == index || (index > 0 && (visiblyPage == index - 1 || visiblyPage == index + 1))? FutureBuilder<List<Uint8List>>(
              future:
              reload || oldListPaths[index].isEmpty ?
              loadAssetAll(pathPdf: pathPdf, annotations: annotations, bookmarks: bookmarks, width: width, height: height, zoom: zoom, page: index)
                 : retutnBytes(index, zoom),
              builder: (context, _snapshot) {
                //print(oldListPaths[index].lengthInBytes);
                if(_snapshot.hasData && _snapshot.data != null){
                    oldListPaths[index] = _snapshot.data!.first;
                }
                //if(_snapshot.hasData && _snapshot.data != null)print('image size ${_snapshot.data!.first.lengthInBytes}
                if(index == count){
                  reload = false;
                }
                if(_snapshot.hasData){
                  return  StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState)=> Center(
                          child: GestureDetector(
                              onTap: () => onTap(index),
                              onPanStart: (v) => onPanStart(v, index, setState),
                              onPanEnd: (v) => onPanEnd(v, index, setState),
                              onPanUpdate: (details) =>
                                  onPanUpdate(details, index, setState),
                              child: VisibilityDetector(
                                  key: ValueKey("$index"),
                                  onVisibilityChanged: (VisibilityInfo info) => onVisibilityChanged(info),
                                  child: RotatedBox(
                                      quarterTurns: rotation,
                                      child: Container(
                                          key: globalKeys[index],
                                          margin: const EdgeInsets.fromLTRB(
                                              5, 5, 5, 5),
                                          child: Stack(
                                              children: [

                                          Platform.isIOS || Platform.isAndroid ? PinchZoomReleaseUnzoomWidget(
                                              twoFingersOn: () =>  blockScroll = true,
                                          twoFingersOff: () => Future.delayed(
                                            PinchZoomReleaseUnzoomWidget.defaultResetDuration,
                                                () =>  blockScroll = false,
                                          ),
                                          fingersRequiredToPinch: 2,
                                          child:Image.memory(
                                                  _snapshot.data!.first,
                                                  //scale: 1,
                                                ),
                                          )
                                                : Image.memory(
                                  _snapshot.data!.first,
                                    //scale: 1,
                                  ),
                                                ///рисуем выделения найденого текста
                                                ...findedFragments.where((el) => el.pageIndex == index).toList().map((e) => Positioned(
                                                    top:e.bounds!.top * aspectCoefY,
                                                    left: e.bounds!.left * aspectCoefX,
                                                    child: Container(
                                                      color: Colors.yellow.withOpacity(0.7),
                                                      width: (e.bounds!.width > 0 ? e.bounds!.width : 30) * aspectCoefX,
                                                      height: e.bounds!.height * aspectCoefY,
                                                    ))).toList(),

                                                // ...selectedFragments[index].map((e) => Positioned(
                                                //     top:e.top * aspectCoefY,
                                                //     left: e.left * aspectCoefX,
                                                //     child: Container(
                                                //       color: Colors.orange.withOpacity(0.3),
                                                //       width: (e.width > 0 ? e.width : 30) * aspectCoefX,
                                                //       height: e.height * aspectCoefY,
                                                //     ))).toList(),
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
                                                 ...lines[index].map((e)=>FingerPaint(line:  e.line, mode: AnnotState.values.firstWhere((el) => el.name == e.subject)/*mode == AnnotState.erase ? AnnotState.freeForm : mode*/, color: e.color, thickness: e.thickness, )).toList(),
                                                ...annotations!.where((element) =>
                                                element.page == index)
                                                    .toList().map((e){
                                                  e.aspectCoefX = aspectCoefX;
                                                  e.aspectCoefY = aspectCoefY;
                                                  return FingerPaint(line: e.points.map((p) => Offset(p.x  * aspectCoefX, p.y  * aspectCoefY)).toList(), mode: e.subject == 'selectText' ? AnnotState.selectText : AnnotState.freeForm, color: Color(e.color!.toInt()) , thickness: e.border!.width, );
                                                }).toList(),
                                                ///рисуем обводку у выделлной аннотации
                                                ...annotations.where((element) =>
                                                element.uuid == selectedUuid && element.page == index)
                                                    .toList().map((e){
                                                  e.aspectCoefX = aspectCoefX;
                                                  e.aspectCoefY = aspectCoefY;
                                                  return FingerPaint(line: e.points.map((p) => Offset(p.x  * aspectCoefX, p.y  * aspectCoefY)).toList(), mode: AnnotState.freeForm, color: Colors.orangeAccent , thickness: 4, );
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

                                              ])
                                      )
                                  )
                              )
                          )
                      )
                  );
                }else{
                  return Container(
                    color: Colors.white,
                    width: screenWidth,
                    height: screenHeight,
                  );
                }

              }
          )
              : StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => VisibilityDetector(
                  key: ValueKey("$index"),
                  onVisibilityChanged: (VisibilityInfo info) => onVisibilityChanged(info),
                  child: Container(
                margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
            color: Colors.white,
            width: screenWidth,
            height: screenHeight,
          )
          )
                    )

          );

          return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              scrollDirection: scrollDirection!,
              controller: scrollController,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _children
              )
          );
        });
  }

  getBlocks(int page, annotations){

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