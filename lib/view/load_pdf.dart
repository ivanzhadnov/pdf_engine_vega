import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as path;
import 'package:pdf_engine_vega/view/widgets/annot_eraser.dart';
import 'package:pdfium_bindings/pdfium_bindings.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

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
    if (!(Platform.isIOS || Platform.isWindows || Platform.isAndroid)) sysInfo = CurrentSystemInformation();

    try{
      if(!Platform.isMacOS)pdfium!.dispose();
    }catch(e){}

    String libraryPath = '';
    final directory = await getApplicationDocumentsDirectory();
    if(Platform.isAndroid){
      // String libAsset = 'assets/libpdf/libpdfium_android.so';
      // // if(sysInfo!.kernelBitness == 32){
      // //   if(sysInfo.kernelArchitecture == ProcessorArchitecture.x86){
      // //     libAsset = 'assets/libpdf/libpdfium_android_32_x86.so';
      // //   }else{
      // //     libAsset = 'assets/libpdf/libpdfium_android_32.so';
      // //   }
      // //
      // // }
      // final String localPath = directory.path;
      // File file = File('$localPath/libpdfium_android.so');
      // bool exist = await file.exists();
      // if(!exist){
      //   print('файла библиотеки нет, поэтому копируем его из ассет');
      //   final asset = await rootBundle.load(libAsset);
      //   final buffer = asset.buffer;
      //   await file.writeAsBytes(buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes));
      // }
      // libraryPath = file.path;
    }
    else if(Platform.isMacOS){
      libraryPath = 'libpdfium.dylib';
    }
    else if(Platform.isIOS){
      // final String localPath = directory.path;
      // File file = File(path.join(localPath, 'libpdfium_ios.dylib'));
      // libraryPath = file.path;
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
  PdfDocument? pdfDocument;


  Size chkSize= Size(0, 0);

  ///настройки толщины и цвета линии аннотирования
  double thickness = 4;
  Color color = Colors.blue;

  ///загрузка файла PDF целиком
  Future<List<Uint8List>> loadAssetAll({
    required String pathPdf,
    List<AnnotationItem>? annotations,
    List<BookMarkPDF>? bookmarks = const [],
    double? width,
    double? height,
    int? page,

    String? color,
  }) async {
    //print('загрузили по новой $page zoom $zoom');
    List<Uint8List> filesPaths = [];

      String _path = pathPdf;

      ///получаем исходные размеры документа, чтоб потом подстраивать рисование
      bornDocSize = await getPageSize(pathPdf: pathPdf);
      aspectRatioDoc = bornDocSize.aspectRatio;
      width = bornDocSize.width;
      height = bornDocSize.height;

      screenWidth = width;
      screenHeight = height;
      aspectCoefX = width / bornDocSize.width;
      aspectCoefY = height / bornDocSize.height;

      //final directory = await getApplicationDocumentsDirectory();
      //String fileName = 'render';
      int pageCount = page != null ? 0 : await getPageCount(pathPdf:  _path);

      if(Platform.isIOS || Platform.isAndroid || Platform.isWindows){

        ///добавляем аннотации если они есть или были нарисованы
        _path =  await syficionAddAnnotation(pathPdf: pathPdf, annotations: annotations, bookmarks: bookmarks, page: page, addContent: false);
        loadComplite = true;
        pdfDocument ??= await PdfDocument.openFile(_path);

        if(page == null){
          for (int i = 1; i <= pageCount; i++) {
            final pdfPage = await pdfDocument!.getPage(i);
            double pdfWidth = screenWidth * 2;
            double pdfHeight = screenHeight * 2;
            if(Platform.isWindows || Platform.isAndroid){
              pdfWidth = pdfPage.width * 4;
              pdfHeight = pdfPage.height * 4;
            }
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
          if(visiblyPage == page){
            final pdfPage = await pdfDocument!.getPage(page + 1);
            double pdfWidth = screenWidth * 2;
            double pdfHeight = screenHeight * 2;
            if(Platform.isWindows || Platform.isAndroid){
              pdfWidth = pdfPage.width * 4;
              pdfHeight = pdfPage.height * 4;
            }
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
          }else{
            //print('пропустили загрузку');
            filesPaths.add(Uint8List(0));
          }
        }

        //await pdfDocument!.close();
      }
      else{
        if(document == null){
          ///добавляем аннотации если они есть или были нарисованы
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
          List<int> _rotation = await getPageRotation(pathPdf: pathPdf,);

          for(int i = 0; i < pageCount; i++){
            int realWidth = 0;
            int realHeight = 0;

            Size size = await getPageSize(pathPdf: pathPdf, page: i);


            if(_rotation[i] == 0 || _rotation[i] == 2){
              realWidth = (size.width).toInt();
              realHeight = (size.height).toInt();
            }else{
              realWidth = _rotation[i] == 0 || _rotation[i] == 2 ? screenWidth.toInt() : screenHeight.toInt();
              realHeight = _rotation[i] != 0 && _rotation[i] != 2 ? screenWidth.toInt() : screenHeight.toInt();
            }

            final _bytes = document!.loadPage(i).renderPageAsBytes(realWidth * 2, realHeight * 2, flags: 0,);
            final img.Image image = img.Image.fromBytes(
              width: realWidth * 2,
              height: realHeight * 2,
              bytes: _bytes.buffer,
              order: img.ChannelOrder.bgra,
              numChannels: 4,
            );
            final _bytes2 = img.encodeJpg(image, quality: 100);

            // document!.loadPage(i).
            // savePageAsJpg('${directory.path}${Platform.pathSeparator}$fileName$i.jpg', qualityJpg: 100, flags: 0, width: realWidth * 2, height: realHeight * 2, backgroundColor: int.parse((color ?? '#FFFFFFFF').replaceAll('#', '0x')))
            //     .closePage();
            // final _bytes = await File('${directory.path}${Platform.pathSeparator}$fileName$i.jpg').readAsBytes();
            filesPaths.add(_bytes2);
          }
        }
        else{
          if(visiblyPage == page){
          List<int> rotation = await getPageRotation(pathPdf: pathPdf, page: page);
          Size size = await getPageSize(pathPdf: pathPdf, page: page);
          chkSize = size;
          int realWidth = 0;
          int realHeight = 0;
          if(rotation.first == 0 || rotation.first == 2){
            realWidth = (size.width).toInt();
            realHeight = (size.height).toInt();
          }else{
            realWidth = rotation.first == 0 || rotation.first == 2 ? screenWidth.toInt() : screenHeight.toInt();
            realHeight = rotation.first != 0 && rotation.first != 2 ? screenWidth.toInt() : screenHeight.toInt();
          }

          final _bytes = document!.loadPage(page).renderPageAsBytes(realWidth * 2, realHeight * 2, flags: 0,);
          final img.Image image = img.Image.fromBytes(
            width: realWidth * 2,
            height: realHeight * 2,
            bytes: _bytes.buffer,
            order: img.ChannelOrder.bgra,
            numChannels: 4,
          );
          final _bytes2 = img.encodeJpg(image, quality: 100);

          //document!
          //.loadPage(page)
          //.savePageAsJpg('${directory.path}${Platform.pathSeparator}$fileName$page.jpg', qualityJpg: 100, flags: 0, width: realWidth * 2, height: realHeight * 2,).closePage();
          // final _bytes = File('${directory.path}${Platform.pathSeparator}$fileName$page.jpg').readAsBytesSync();
          filesPaths.add(_bytes2);
          }else{
            //print('пропустили загрузку');
            filesPaths.add(Uint8List(0));
          }
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
  PageController scrollController = PageController(
      keepPage: true, viewportFraction: 0.73,
  );

  ///переменные для работы с ластиком
  double eraseRadius = 10.0;
  Offset erasePosition = const Offset(-100, -100);
  List<List<List<Offset>>> erasePositions = [];
  ///формируем разорванные ластиком массивы, после добавим их в основной массив
  List<DrawLineItem> brokenLists = [];
  String searchTextString = '';


  int? _page;

  ///обрабатываем нажатие по скролл контроллеру
  ///нужно дождаться пока перестанут тыкать и перейти на нужную страницу
  changePage(int page, setState){
      //print('отработали нажатие');
        if(oldListPaths.length > 1){
          scrollController.jumpToPage(page);
          visiblyPage =  page;
          _page = null;
          setState();
        }
  }

  int count = 0;
  Future<List<Uint8List>>retutnBytes(int index,)async{
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
    bool? fullScreenMode = false,
    ///поворот документа
    int rotation = 0,
    ///получаем режим рисования из вне
    required AnnotState mode,
    ///требуемая к выполнению внешняя функция
    dynamic func,
    bool scaleEnabled = true,
    ///строка поиска
    String? searchString,
  }){

    pathDocument = pathPdf;

    ///обработка начала рисования
    void onPanStart(DragStartDetails v, int index, setState){
      ///зафиксировали начало выделения текста
     // startSelectTextPoint = v.localPosition;
      if(mode == AnnotState.erase){
        erasePositions[index].add([]);
        //setState((){});
        func();
      }
    }
    ///обработка завершения рисования линии и подготовка новой линии
    void onPanEnd(v, int index, setState){
      ///формируем ровную и без лишних точек линию выделения текста, так эстетичнее и уменьшается нагрузка
      if(mode == AnnotState.erase){
        erasePositions[index] = [];
      }else if(mode == AnnotState.selectText || mode == AnnotState.freeForm){
        if(lines[index].isNotEmpty){
          //final color = lines[index].last.color;
          //final thicknes = lines[index].last.thickness;
          lines[index].add(DrawLineItem(subject: mode.name, uuid: Uuid().v4()));
          lines[index].last.color = color;
          lines[index].last.thickness = thickness;
        }else{
          lines[index].add(DrawLineItem(subject: mode.name, uuid: Uuid().v4()));
        }

        yLine = -1;
        try{
          func();
        }catch(e){}
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

        ///выделяем текст
        if(mode == AnnotState.selectText){
          //endtSelectTextPoint = current;
          if(textLines.isNotEmpty && textLines[visiblyPage].isNotEmpty && lines[index].isNotEmpty){
            lines[index].last.subject = 'selectText';
            lines[index].last.line = [];
           }
        }
        ///рисуем линии
        else{
          if(lines[index].isEmpty){
            lines[index].add(DrawLineItem(subject: mode.name, uuid: Uuid().v4()));
          }
          ///просто рисуем кривую
          lines[index].last.line.add(Offset(x, y));
        }
        try{
          func();
        }catch(e){}
      }
      ///режим стирания
      else if(mode == AnnotState.erase){
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
            final tmpFirst = DrawLineItem(uuid: lines[index][i].uuid, subject: lines[index][i].subject)..color = color..thickness=thickness..undoLine=lines[index][i].undoLine..undoColor=lines[index][i].undoColor..undoThickness=lines[index][i].undoThickness;
            final tmpSecond = DrawLineItem(uuid: lines[index][i].uuid, subject: lines[index][i].subject)..color = color..thickness=thickness..undoLine=lines[index][i].undoLine..undoColor=lines[index][i].undoColor..undoThickness=lines[index][i].undoThickness;
            tmpFirst.line = lines[index][i].line.map((e) => e).toList().sublist(0, splitIndex);
            tmpSecond.line = lines[index][i].line.map((e) => e).toList().sublist(splitIndex);
            brokenLists..add(tmpFirst)..add(tmpSecond);
          }else{
            brokenLists.add(lines[index][i]);
          }
        }
        lines[index] = brokenLists;
        brokenLists = [];
        try{
          func();
        }catch(e){}
      }
    }


    bool reload = false;



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


          List<Widget> _children = List.generate(count, (index) => index == 0 || visiblyPage == index || (index > 0 && (visiblyPage == index - 1 || visiblyPage == index + 1 || visiblyPage == index + 2))? FutureBuilder<List<Uint8List>>(
              future: reload || oldListPaths[index].isEmpty ? loadAssetAll(pathPdf: pathPdf, annotations: annotations, bookmarks: bookmarks, page: index) : retutnBytes(index,),
              builder: (context, _snapshot) {
                if(_snapshot.hasData && _snapshot.data != null){
                  oldListPaths[index] = _snapshot.data!.first;
                }
                if(index == count){
                  reload = false;
                }
                if(index > 12){
                  ///очищаем память
                  oldListPaths[index - 2] = Uint8List(0);
                }
                if(_snapshot.hasData){
                  final _child = Container(
                    color: Colors.transparent,
                    margin: const EdgeInsets.fromLTRB(0, 0, 5, 5),
                    child: RotatedBox(
                      quarterTurns: rotation,
                      child: Stack(
                          alignment: AlignmentDirectional.topStart,
                          children: [
                            Image.memory(
                              _snapshot.data!.first,
                              key: globalKeys[index],
                              filterQuality: FilterQuality.high,
                                errorBuilder: (BuildContext, Object, StackTrace)=>Container(),
                            ),
                            if(searchString != '' && textLines.isNotEmpty)...textLines[visiblyPage].where((el) => el.text.toUpperCase().contains((searchString ?? '').toUpperCase())).toList().map((e) => Positioned(
                                top:e.bounds.top,
                                left: e.bounds.left,
                                child: Container(
                                  color: Colors.yellow.withOpacity(0.5),
                                  width: (e.bounds.width > 0 ? e.bounds!.width : 30),
                                  height: e.bounds.height,
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
                            ...lines[index].map((e)=>FingerPaint(line:  e.line, mode: AnnotState.values.firstWhere((el) => el.name == e.subject), color: e.color, thickness: e.thickness, )).toList(),
                            ...annotations!.where((element) =>
                            element.page == index)
                                .toList().map((e){

                              return FingerPaint(line: e.points.map((p) => Offset(p.x  * aspectCoefX, p.y  * aspectCoefY)).toList(), mode: e.subject == 'selectText' ? AnnotState.selectText : AnnotState.freeForm, color: Color(e.color!.toInt()) , thickness: e.border!.width, );
                            }).toList(),
                            ///рисуем обводку у выделлной аннотации
                            ...annotations.where((element) =>
                            element.uuid == selectedUuid && element.page == index)
                                .toList().map((e){
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
                            if(mode == AnnotState.selectText)SelectionArea(

                                onSelectionChanged: (v){
                                  //print(v!.plainText);
                                },
                                contextMenuBuilder: (context, state){
                                  startSelectTextPoint = state.selectionEndpoints.first.point;
                                  endtSelectTextPoint = state.selectionEndpoints.last.point;
                                  final selectedTextLines = [];
                                  for(int i = 0; i < textLines[visiblyPage].length; i++){
                                    if(textLines[visiblyPage][i].bounds.top >= startSelectTextPoint.dy - 30
                                    && textLines[visiblyPage][i].bounds.bottom <= endtSelectTextPoint.dy + 10
                                    ){selectedTextLines.add(textLines[visiblyPage][i]);}
                                  }
                                  List<sf.TextWord> selectedWords = [];
                                  for(int i=0; i< selectedTextLines.length; i++){
                                    for(int ii = 0; ii < selectedTextLines[i].wordCollection.length; ii++){
                                      if(i == 0 && selectedTextLines[i].wordCollection[ii].bounds.left >= startSelectTextPoint.dx - 10){
                                        selectedWords.add(selectedTextLines[i].wordCollection[ii]);
                                      }
                                     else if(i == selectedTextLines.length -1 && selectedTextLines[i].wordCollection[ii].bounds.right <= endtSelectTextPoint.dx + 10){
                                        selectedWords.add(selectedTextLines[i].wordCollection[ii]);
                                      }
                                      else if(i != 0 && i != selectedTextLines.length -1){
                                        selectedWords.add(selectedTextLines[i].wordCollection[ii]);
                                      }
                                    }

                                  }


                                  return AdaptiveTextSelectionToolbar.buttonItems(
                                    buttonItems: <ContextMenuButtonItem>[
                                      ContextMenuButtonItem(
                                        onPressed: () {
                                          bookmarks!.add(BookMarkPDF(
                                            page: visiblyPage,
                                            offset: const Offset(10.0, 0.0),
                                            content: selectedWords.map((e) => e.text).toList().join( ' ')
                                          ),);
                                          func();
                                        },
                                        type: ContextMenuButtonType.custom,
                                        label: 'Закладка',
                                      ),
                                      ContextMenuButtonItem(
                                        onPressed: () {
                                          ///берем массив и пока строка не изменилась набираем края первого прямоугольника удаляя строки из массива
                                          ///набираем второй прямоугольник, пока его строка не изменилась, а потом меняем местами углы
                                          ///набираем третий пока строка не изменилась не меняя местями углы и так до последней строки
                                          ///последнюю строку
                                          List<List<sf.TextWord>> arr = [];
                                          for(int i=0; i< selectedWords.length; i++){
                                          if(i == 0 || selectedWords[i].bounds.top != arr.last.last.bounds.top){
                                            arr.add(<sf.TextWord>[]);
                                          }
                                          arr.last.add(selectedWords[i]);
                                          }
                                          print('выделено строк ${arr.length}');
                                          for(int i = 0; i < arr.length; i++){
                                            if(arr[i].length == 1){
                                              arr[i].add(arr[i].last);
                                            }
                                            if(arr[i].length > 2){
                                              //arr[i].removeRange(1, arr.length - 1);
                                              arr[i] = [arr[i].first, arr[i].last];
                                            }
                                            if(i%2 != 0){
                                              arr[i] =  List.from(arr[i].reversed);
                                            }
                                          }

                                          List<Offset> offsets = [];
                                          for(int i = 0; i < arr.length; i++){
                                            if(i == 0){
                                              offsets.add(arr[i].first.bounds.bottomLeft);
                                              offsets.add(arr[i].first.bounds.topLeft);
                                              offsets.add(arr[i].last.bounds.topRight);
                                              offsets.add(arr[i].last.bounds.bottomRight);
                                            }
                                            else if(i == arr.length - 1){
                                              offsets.add(arr[i].last.bounds.topRight);
                                              offsets.add(arr[i].last.bounds.bottomRight);
                                              offsets.add(arr[i].first.bounds.bottomLeft);
                                              offsets.add(arr[i].first.bounds.topLeft);

                                            }else{
                                              offsets.add(arr[i].last.bounds.topRight);
                                              offsets.add(arr[i].last.bounds.bottomRight);
                                            }
                                          }
                                          for(int i = 0; i < arr.length; i++){
                                            if(i != 0 && i != arr.length - 1){
                                              offsets.add(arr[i].first.bounds.bottomLeft);
                                              offsets.add(arr[i].first.bounds.topLeft);
                                            }

                                          }
///flutter: Offset(231.4, 77.4)
// flutter: Offset(529.2, 77.4)
// flutter: Offset(503.0, 89.4)
// flutter: Offset(231.4, 89.4)
// flutter: Offset(231.4, 101.4)
// flutter: Offset(231.4, 101.4)



                                          lines[visiblyPage].add(DrawLineItem(subject: 'selectText', uuid: Uuid().v4()));
                                          lines[visiblyPage].last.text = selectedWords.map((e) => e.text).toList().join( ' ');
                                          for(int i = 0; i < selectedWords.length; i++){
                                            lines[visiblyPage].last.line = offsets;

                                          }
                                          //print(lines[visiblyPage].last.line);

                                          ///заводим массив массивов
                                          List<List<Rect>> rects = [];
                                          ///смотрим, если значение высоты отличается, пишем вследующий массив массива
                                          ///далее первую и последнюю строки не трогаем
                                          ///а все что по середине четные переворачиваем наоборот


                                          func();
                                        },
                                        type: ContextMenuButtonType.custom,
                                        label: 'Аннотация',
                                      ),
                                    ],
                                    //anchors: state.contextMenuAnchors,
                                    anchors: state.context.findRenderObject() != null ? TextSelectionToolbarAnchors.fromSelection(renderBox: state.context.findRenderObject()! as RenderBox, startGlyphHeight: 0, endGlyphHeight: 0, selectionEndpoints: [TextSelectionPoint(Offset(startSelectTextPoint.dx, startSelectTextPoint.dy - 20), TextDirection.ltr),TextSelectionPoint(Offset(startSelectTextPoint.dx, startSelectTextPoint.dy - 20), TextDirection.ltr)]) : state.contextMenuAnchors,
                                  );
                                },
                                child: Stack(
                                  children: [
                                    if(textLines.isNotEmpty && mode == AnnotState.selectText)...textLines[visiblyPage].map((line){
                                      return Positioned(
                                        top:line.bounds.top,
                                        left: line.bounds.left,
                                        child: Container(
                                          //color: Colors.blue.withOpacity(0.2) : Colors.transparent,
                                          //color: Colors.orangeAccent.withOpacity(0.2),
                                          width: (line.bounds.width > 0 ? line.bounds.width : 30),
                                          height: line.bounds.height,
                                          child: FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: Text(line.text + ' ', style: TextStyle(fontSize: line.bounds.height,  color: Colors.transparent, ),),
                                          )
                                        ),
                                      );
                                    }).toList()
                                  ],
                                )
                            ),

                          ]),
                    ),
                  );
                  return  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState)=> mode != AnnotState.inactive ? GestureDetector(
                        onPanStart: (v) => null,
                        onPanEnd: (v) => onPanEnd(v, index, setState),
                        onPanUpdate: (details) => onPanUpdate(details, index, setState),
                        child: _child,
                          ) : _child,
                  );
                }else{
                  return Container(
                    alignment: Alignment.center,
                    child: const SizedBox(width: 40, height: 40, child: CircularProgressIndicator()),
                  );
                }

              }
          )
              : Container(
                alignment: Alignment.center,
                child: const SizedBox(width: 40, height: 40, child: CircularProgressIndicator()),
              ),
          );

          returnWidth(){
            if(screenWidth < height!){
              return rotation == 0 || rotation == 2 ? screenWidth : screenHeight;
            }else{
              //return rotation == 0 || rotation == 2 ? width : height;
              return rotation == 0 || rotation == 2 ? screenWidth : screenHeight;
            }
          }

          returnHeight(){
            if(screenWidth < height!){
              scrollController = PageController(
                keepPage: true, viewportFraction: 1,
              );
              return rotation == 0 || rotation == 2 ? screenHeight : screenWidth;
            }else{
              scrollController = PageController(
                keepPage: true, viewportFraction: 0.73,
              );
              //return rotation == 0 || rotation == 2 ? height : width! * 0.77;
              return rotation == 0 || rotation == 2 ? screenHeight : screenWidth;
            }
          }


          return Container(
            color: Colors.transparent,
            //height: returnHeight() ,
            height: MediaQuery.of(context).size.width < MediaQuery.of(context).size.height ? MediaQuery.of(context).size.width : returnHeight(),
            //width: returnWidth(),
            width: MediaQuery.of(context).size.width < MediaQuery.of(context).size.height ? MediaQuery.of(context).size.width : returnWidth(),
            alignment: Alignment.center,
            child: InteractiveViewer(
                //constrained:false,
              scaleEnabled: !(fullScreenMode ?? false) ? scaleEnabled : false,
              panEnabled: scaleEnabled,
                  trackpadScrollCausesScale: false,
                  //boundaryMargin: const EdgeInsets.all(0.0),
                  minScale: 1,
                  maxScale: 8,
                  onInteractionStart: (v){},
                  onInteractionEnd: (v){},
                  onInteractionUpdate: (v){},
                  child: PageView(

                    padEnds: true,
                    scrollBehavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: false,
                      overscroll: true,
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    //physics: mode == AnnotState.inactive ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
                    scrollDirection: scrollDirection!,
                    pageSnapping: false,
                    controller: scrollController,
                    reverse: false,
                    onPageChanged: (int index) {
                      visiblyPage = index;
                      func();
                    },
                    children: _children + [SizedBox(height: MediaQuery.of(context).size.height,)],
                  ),
                ),
          );
        });
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

  List<Offset> boundsToOffsets(Rect bounds){
    List<Offset> points = [
      bounds.bottomLeft,
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomRight,
      bounds.bottomLeft,
    ];
    return points;
  }