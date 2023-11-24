import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_engine_vega/view/view_ios.dart';
import 'package:pdfium_bindings/pdfium_bindings.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../edit/annot_buttons.dart';
import '../edit/annot_painter.dart';
import '../edit/annotation_class.dart';
import '../edit/annotation_core.dart';
import 'package:pdf_engine_vega/pdf_engine_vega.dart' as PDF;



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

  List<List<List<Offset>>> lines = [];
  double yLine = -1;

  ///массив работы с кнопками в режиме редактирования аннотаций
  List<AnnotState> buttons = [];

  ///массив для опредделения размеров окна с отображаемой страницей
  List<GlobalKey> globalKeys = [];


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
    bool? editable = false
  }){
    bool withAnnot = annotations != null || annotations!.isNotEmpty;

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
          future: withAnnot ? AnnotationPDF().addAnnotation(pathPdf: pathPdf, annotations: annotations).then((value)=>loadAssetAll(pathPdf: value,)) : loadAssetAll(pathPdf: pathPdf,),
          builder: (context, snapshot) {
            if(snapshot.hasData && lines.length != snapshot.data!.length ){
              lines = List.generate(snapshot.data!.length, (_) => []);
              globalKeys = List.generate(snapshot.data!.length, (_) => GlobalKey());
              buttons = List.generate(snapshot.data!.length, (_) => AnnotState.inactive);
            }

            List<Widget> children = snapshot.hasData ? snapshot.data!.map((item) => StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) => GestureDetector(
                    onPanStart: (v){
                      if(buttons[snapshot.data!.indexWhere((e) => e == item)] == AnnotState.selectText || buttons[snapshot.data!.indexWhere((e) => e == item)] == AnnotState.freeForm){
                        lines[snapshot.data!.indexWhere((e) => e == item)].add([]);
                        yLine = -1;
                        setState((){});
                      }
                    },
                    onPanEnd: (v){
                      if(buttons[snapshot.data!.indexWhere((e) => e == item)] == AnnotState.selectText){
                        final temp = lines[snapshot.data!.indexWhere((e) => e == item)].last;
                        lines[snapshot.data!.indexWhere((e) => e == item)].last = [temp.first, temp.last];
                        setState((){});
                      }
                    },
                    onPanUpdate: (details) {
                      if(buttons[snapshot.data!.indexWhere((e) => e == item)] == AnnotState.selectText || buttons[snapshot.data!.indexWhere((e) => e == item)] == AnnotState.freeForm){
                        final RenderObject? renderBoxRed =
                        globalKeys[snapshot.data!.indexWhere((e) => e == item)].currentContext!.findRenderObject();
                        final maxHeight = renderBoxRed?.paintBounds.height;
                        final maxWidth = renderBoxRed?.paintBounds.width;

                        double x = 0;
                        double y = 0;

                        if(details.localPosition.dx < maxWidth! && details.localPosition.dx > 0){
                          x = details.localPosition.dx;
                        }else{
                          x = details.localPosition.dx > 0 ? maxWidth - 10 : 0;
                        }
                        if(details.localPosition.dy < maxHeight! && details.localPosition.dy > 0){
                          y = details.localPosition.dy;
                        }else{
                          y = details.localPosition.dy > 0 ? maxHeight - 10 : 0;
                        }


                        if(buttons[snapshot.data!.indexWhere((e) => e == item)] == AnnotState.selectText){
                          ///рисуем горизонтальную прямую
                          if(yLine == -1){
                            yLine = y;
                          }
                          lines[snapshot.data!.indexWhere((e) => e == item)].last.add(Offset(x, yLine));
                        }else{
                          ///просто рисуем кривую
                          lines[snapshot.data!.indexWhere((e) => e == item)].last.add(Offset(x, y));
                        }
                        setState((){});
                      }
                    },
                    child: Container(
                        key: globalKeys[snapshot.data!.indexWhere((e) => e == item)],
                        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                        child: Stack(
                          children: [
                            Image.asset(item),
                            ///интегрируется виджет области аннотации
                            ...annotations.where((element) =>
                            element.page == snapshot.data!.indexWhere((e) => e == item))
                                .toList().map((e) => e.tapChild)
                                .toList(),
                            ...lines[snapshot.data!.indexWhere((e) => e == item)].map((e)=>FingerPaint(line:  e, mode: buttons[snapshot.data!.indexWhere((e) => e == item)])).toList(),
                            ManageAnnotButtons(
                              mode: buttons[snapshot.data!.indexWhere((e) => e == item)],
                              onDrawTap: ()=>setState(()=>buttons[snapshot.data!.indexWhere((e) => e == item)] = AnnotState.freeForm),
                              onTextTap: ()=>setState(()=>buttons[snapshot.data!.indexWhere((e) => e == item)] = AnnotState.selectText),
                              onClearTap: ()=>setState((){
                                buttons[snapshot.data!.indexWhere((e) => e == item)] = AnnotState.inactive;
                                lines.removeAt(snapshot.data!.indexWhere((e) => e == item));
                              }),
                              onAproveTap: ()=>addCommentDialog(context).then((value){
                                if(value){
                                  AnnotationItem newAnnot = AnnotationItem(
                                    subject: buttons[snapshot.data!.indexWhere((e) => e == item)].name,
                                    author: 'Народ',
                                    page: snapshot.data!.indexWhere((e) => e == item),
                                    annotationType: AnnotationType.inkAnnotation,
                                    color: buttons[snapshot.data!.indexWhere((e) => e == item)] == AnnotState.freeForm ? PDF.PdfColors.blue : PDF.PdfColor.fromHex('#00ff0080'),
                                    border: PDF.PdfBorder(PDF.PdfDocument(), buttons[snapshot.data!.indexWhere((e) => e == item)] == AnnotState.freeForm ? 4 : 12),
                                    //interiorColor: PDF.PdfColors.blue,
                                    pointsInk:lines[snapshot.data!.indexWhere((e) => e == item)].map((e) => AnnotationItem(page: 0, annotationType: AnnotationType.inkAnnotation).convertPointsType(e)).toList()  ,
                                    content: commentBody,
                                    date: DateTime.now(),

                                  );
                                  //print(AnnotationItem.fromMap({'uuid': null, 'page': 2, 'annotationType': 'inkAnnotation', 'color': '#00ff0080', 'border': null, 'author': 'Народ', 'date': 1700828655376, 'content': 'мссмти', 'subject': 'selectText', 'points': [], 'pointsInk': [[{'x': 67.0625, 'y': 258.1754150390625}, {'x': 446.60546875, 'y': 258.1754150390625}], [{'x': 66.55078125, 'y': 277.0230712890625}, {'x': 392.55078125, 'y': 277.0230712890625}], [{'x': 63.05078125, 'y': 305.4957275390625}, {'x': 376.9375, 'y': 305.4957275390625}]]}));
                                  newAnnot.pointsInk = lines[snapshot.data!.indexWhere((e) => e == item)].map((e) => newAnnot.convertPointsType(e)).toList();
                                  annotations.add(newAnnot);
                                  setState((){
                                    buttons[snapshot.data!.indexWhere((e) => e == item)] = AnnotState.inactive;
                                    lines.removeAt(snapshot.data!.indexWhere((e) => e == item));
                                  });
                                  func();
                                }
                              }),
                            )
                          ],
                        )
                    )
                ))).toList() : [];

            return !snapshot.hasData
                ? const Center( child: SizedBox(width: 60, height: 60, child: CircularProgressIndicator()))
                : scrollDirection == Axis.horizontal ? ListView(
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  scrollDirection: scrollDirection!,
                  children: children
            ) : SingleChildScrollView(
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


