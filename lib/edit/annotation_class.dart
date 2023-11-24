
import 'package:flutter/cupertino.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_engine_vega.dart';
import 'package:flutter/material.dart' as Material;

///перечисление возможных типов аннотаций
enum AnnotationType{
  ///для рисования выделений строки используем полигон с координатами задающими выделенную область
  polygonAnnotation,
  ///для рисования произвольной линии используем ломанню линию с заданием координат (например провели пальцем и собрали ломанную линию обводки чего либо)
  polyLineAnnotation,
  ///для формирования подписи может потребоваться множество полилиний, в данном типе аннотации задается массив массиов координат полилний
  inkAnnotation,
  ///задается область нажатия на экран при котрой происходит действие нажатия на гиперссылку (переход на вебсайт или прокрутка страницы)
  annotationUrl,
  ///задается область нажатия в котрой появляется текстовое поле ввода
  annotationTextField
}


///описание аннотации для загрузки и выгрузки, а так же авто подбор нужного виджета для вставляемой и отображаемой на экране аннотации
class AnnotationItem{
  ///так как на одной странице может быть несколько аннотаций мы указываем номер страницы в документе, где лежит сия аннотация
  int page;
  ///Указание типа аннотации
  AnnotationType annotationType;
  ///цвет рамки
  PdfColor? color;
  ///цвет заливки
  PdfColor? interiorColor;
  ///определитель бордюра PdfBorder(PdfDocument(), 1)
  PdfBorder? border;
  ///автор аннотации
  String? author;
  ///дата создания аннотации
  DateTime? date;
  ///краткое описание аннотации
  String? subject;
  ///текст аннотации
  String? content;
  ///координаты точек для полигона и полилиний
  ///размеры области нажатия для аннотаций [annotationUrl] и [annotationTextField]
  ///отступы справа и с лева для координации блоков [annotationUrl] и [annotationTextField] на странице
  List<PdfPoint>? points;
  ///координаты точек для рисования марером (массив в массиве)
  List<List<PdfPoint>> pointsInk;

  ///виджет аннотации для инбекции его в документ
  pw.Widget child = pw.Container();
  ///виджет аннотации для формирования дерева виджетов во внутреннем просмотрщике и создания кликабельности по аннотации
  Material.Widget tapChild = Material.Container();

  ///тестируем рисование новой аннтотации
  List<Material.Offset> line = [];

  AnnotationItem({
    required this.page,
    required this.annotationType,
    this.color = PdfColors.black,
    this.interiorColor,
    this.border,
    this.author,
    this.date,
    this.content,
    this.subject,
    this.points = const [],
    this.pointsInk = const [],
  }){
    child = setAnnotationWidget();
    tapChild = setWidgetTreeWidget();
  }

  ///формируем виджеты PDF документа для имплантации в него аннотаций. 
  ///Это нужно при открытии документа во внешнем бразере или если им поделятся и потом откроют во внешнем браузере. 
  ///Так же это нужно для визуального отображения аннотации на документе
  pw.Widget setAnnotationWidget(){
    pw.Widget result = pw.Container();
    ///найти минимальное значение для отсупа слева и дальнейшего определения ширины
    ///найти минимальное значение для отсупа сверху и дальнейшего определения высоты
    double top = -1;
    double left = -1;
    double topMax = -1;
    double leftMax = -1;
    points!.forEach((e) {
      if(left == -1){
        left = e.x;
      }
      e.x < left ? left = e.x : null;
      leftMax < e.x ? leftMax = e.x : null;
      if(top == -1){
        top = e.y;
      }
      topMax < e.y ? topMax = e.y : null;
      e.y < top ? top = e.y : null;
    });
    ///найти ширину высоту
    double width = leftMax - left;
    double height = topMax - top;

    switch(annotationType){
      case AnnotationType.polygonAnnotation : {
        result = pw.PolygonAnnotation(
            points: points ?? [],
            color: color,
            interiorColor: interiorColor,
            border: border,
            author: author,
            date: date,
            subject: subject,
            content: content
        );
        break;
      }
      case AnnotationType.polyLineAnnotation : {
        result = pw.PolyLineAnnotation(
            points: points ?? [],
            color: color,
            //border: border,
            author: author,
            date: date,
            subject: subject,
            content: content
        );
        break;
      }
      case AnnotationType.inkAnnotation : {
        result = pw.Opacity(
          child: pw.InkAnnotation(
              points: pointsInk ?? [],
              color: color,
              border: border,
              author: author,
              date: date,
              subject: subject,
              content: content
          ), opacity: subject == 'selectText' ? 0.3 : 1
        );
        break;
      }
      case AnnotationType.annotationUrl : {

        result = pw.Positioned(
            left: left,
            top: top,
            child: pw.Annotation(
                child: pw.Container(
                    width: width,
                    height: height
                ),
                builder: pw.AnnotationUrl(content ?? '')

            )
        );
        break;
      }
      case AnnotationType.annotationTextField : {

        result = pw.Positioned(
            left: left,
            top: top,
            child: pw.Annotation(
                child: pw.Container(
                    width: width,
                    height: height
                ),
                builder: pw.AnnotationTextField(
                  name: 'Annotation$page',
                  border: PdfBorder(PdfDocument(), 2),
                  flags: {PdfAnnotFlags.readOnly} ,
                  date: DateTime.now(),
                  subject: subject,
                  author: author,
                  color: color,
                  backgroundColor: interiorColor,
                  highlighting: PdfAnnotHighlighting.push,
                  maxLength: 100,
                  //alternateName: 'Anno',
                  //mappingName: '',
                  //fieldFlags: ,
                  value: subject,
                  //defaultValue: '',
                  //textStyle:
              )
            )
        );
        break;
      }
    }

    return result;
  }

  ///флаг индикации нажатия по аннотации
  bool widgetTaped = false;

  ///Формируем виджеты для того, чтоб иметь возможность "тапнуть" по аннотации во внутреннем просмотрщике
  Material.Widget setWidgetTreeWidget(){
    ///найти минимальное значение для отсупа слева и дальнейшего определения ширины
    ///найти минимальное значение для отсупа сверху и дальнейшего определения высоты
    double top = -1;
    double left = -1;
    double topMax = -1;
    double leftMax = -1;

    ///если массив [points] не пуст, обрабатываем его
    ///в противном случае бежим по массиву [pointsInk]
    List<PdfPoint> _points = [];
    if(points != null && points!.isNotEmpty){
      _points = points!;
    }else{
      for(int i = 0; i < pointsInk.length; i++){
        _points += pointsInk[i];
      }
      if(_points.isNotEmpty){
        if(_points.first.y == _points.last.y){
          _points.first = PdfPoint(_points.first.x, _points.first.y + 10);
          _points.last = PdfPoint(_points.last.x, _points.last.y - 10);
        }
      }

    }
      _points.forEach((e) {
        if(left == -1){
          left = e.x;
        }
        e.x < left ? left = e.x : null;
        leftMax < e.x ? leftMax = e.x : null;
        if(top == -1){
          top = e.y;
        }
        topMax < e.y ? topMax = e.y : null;
        e.y < top ? top = e.y : null;
      });


    ///найти ширину высоту
    double width = leftMax - left;
    double height = topMax - top;

    return Material.StatefulBuilder(
        builder: (Material.BuildContext context, Material.StateSetter setState)
    {
      return Material.Positioned(
        top: top,
        left: left,
        child: Material.GestureDetector(
          onTap: (){
            ///TODO отработать поведение для разного типа аннотаций
            ///ссылка переход
            ///текстфилд заполнить значение
            ///кривая показать диалог с контентом
            setState((){
              widgetTaped = !widgetTaped;
            });

            showCommentDialog(context,);
          },
          child: Material.Container(
            height: height,
            width: width,
            ///color: widgetTaped ? Material.Colors.red.withOpacity(0.2) : Material.Colors.green.withOpacity(0.2)
            color: Material.Colors.transparent
          ),
        ),
      );
    });
  }

  factory AnnotationItem.fromMap(Map<String, dynamic> json)  => AnnotationItem(
    page: json['page'] ?? 0,
    annotationType: AnnotationType.values.firstWhere((e) => e.name == json['annotationType']),
    color: PdfColor.fromHex(json['color']),
    interiorColor: PdfColor.fromHex(json['interiorColor']),
    border: null,///TODO
    author: json['author'],
    date: DateTime.fromMillisecondsSinceEpoch(json['date']),
    content: json['content'],
    subject: json['subject'],
    points: (json['points'] as List).map((e) => PdfPoint(e['x'], e['y'])).toList().cast<PdfPoint>(),
    pointsInk: [], ///TODO
  );


  Map<String, dynamic> toMap() => {
    "page": page,
    "annotationType": annotationType.name,
    "color": color!.toHex(),
    "interiorColor": interiorColor!.toHex(),
    "border": null, ///TODO
    "author": author,
    "date": date!.millisecondsSinceEpoch,
    "content": content,
    "subject": subject,
    "points": points!.map((e) => {'x' : e.x, 'y': e.y}).toList(),
    "pointsInk": [], ///TODO
  };

  ///диалог ввода комментария в аннотацию
  Future<bool>showCommentDialog(context, ) async {
    bool result = true;
    Material.TextEditingController controller = Material.TextEditingController(text: content);
    Material.FocusNode myFocusNode1 = Material.FocusNode();
    Material.OutlineInputBorder border = const Material.OutlineInputBorder(
        borderRadius: Material.BorderRadius.all(Material.Radius.circular(7.0)),
        borderSide: Material.BorderSide(color: Material.Color(0xFF1D2830), width: 2));
    Material.BoxConstraints constraints = const Material.BoxConstraints(minWidth: 40.0, minHeight: 40.0, maxWidth: 40.0, maxHeight: 40.0);

    await Material.showDialog(
        context: context,
        builder: (context) {
          return Material.StatefulBuilder(
              builder: (Material.BuildContext context, Material.StateSetter setState) {
                void _requestFocus1(){
                  setState(() {
                    Material.FocusScope.of(context).requestFocus(myFocusNode1);
                  });
                }
                return Material.AlertDialog(

                  backgroundColor: Material.Colors.transparent,
                  elevation: 0.0,
                  scrollable: true,
                  contentPadding: const Material.EdgeInsets.fromLTRB(10, 10, 10, 10),
                  insetPadding: const Material.EdgeInsets.all(10),
                  content: Material.Container(
                    padding: const Material.EdgeInsets.fromLTRB(10, 10, 10, 10),
                    width: 300,
                    height: 270,
                    decoration: const Material.BoxDecoration(
                      color: Material.Colors.grey,
                      borderRadius: Material.BorderRadius.all(Material.Radius.circular(11.0),),
                    ),
                    child: Material.Column(
                        mainAxisAlignment: Material.MainAxisAlignment.start,
                        children: [
                          Material.Container(
                              margin: const Material.EdgeInsets.fromLTRB(0,0,0,0),
                              padding: const Material.EdgeInsets.fromLTRB(0,0,0,0),
                              alignment: Material.Alignment.topCenter,
                              width: Material.MediaQuery.of(context).size.width - 40,
                              height: 200,
                              child:Material.TextFormField(
                                autofocus: true,
                                maxLines: 15, minLines: 15, expands: false,
                                maxLength: 1000,
                                onTap: _requestFocus1,
                                focusNode: myFocusNode1,
                                textAlign: Material.TextAlign.left,
                                enabled: true,
                                //style: inputTextStyle,
                                keyboardType: Material.TextInputType.streetAddress,
                                decoration: Material.InputDecoration(
                                  contentPadding: const Material.EdgeInsets.only(
                                      left: 15,
                                      top: 10,
                                      bottom: 10
                                  ),
                                  counter: Material.SizedBox.shrink(),
                                  //hintStyle: inputHintTextStyle,
                                  hintText: "Комментарий",
                                  border: border,
                                  focusedBorder: border,
                                  enabledBorder: border,
                                  errorBorder: border,
                                  labelText: 'Комментарий',
                                  labelStyle: Material.TextStyle(fontSize: 15.0, color: myFocusNode1.hasFocus ? const Color(0xFF1D2830) : Material.Colors.black,fontFamily: 'Inter'),
                                ),
                                onChanged: (_){setState(() {
                                  //postalEmpty = false;
                                });},
                                //validator: (value) => postalEmpty ? 'Поле адрес не должно быть пустым' : null,
                                autovalidateMode: Material.AutovalidateMode.always,
                                controller: controller,
                              )),
                          Material.Row(
                            mainAxisAlignment: Material.MainAxisAlignment.center,
                            children: [
                              Material.RawMaterialButton(
                                constraints: constraints,
                                onPressed: (){
                                  content = '';
                                  result = false;
                                  Navigator.of(context).pop();
                                },
                                elevation: 2.0,
                                fillColor: Material.Colors.indigo,
                                padding: const Material.EdgeInsets.all(5.0),
                                shape: const CircleBorder(),
                                child: const Material.Icon(CupertinoIcons.trash, color: Material.Colors.red,),
                              ),
                              Material.RawMaterialButton(
                                constraints: constraints,
                                onPressed: (){

                                  content = '';
                                  result = false;
                                  Navigator.of(context).pop();
                                },
                                elevation: 2.0,
                                fillColor: Material.Colors.indigo,
                                padding: const Material.EdgeInsets.all(5.0),
                                shape: const CircleBorder(),
                                child: const Material.Icon(CupertinoIcons.clear, color: Material.Colors.white,),
                              ),
                              Material.RawMaterialButton(
                                constraints: constraints,
                                onPressed: (){
                                  content = controller.text;
                                  result = true;
                                  Material.Navigator.of(context).pop();
                                },
                                elevation: 2.0,
                                fillColor: Material.Colors.indigo,
                                padding: const Material.EdgeInsets.all(5.0),
                                shape: const Material.CircleBorder(),
                                child: const Material.Icon(CupertinoIcons.check_mark, color: Material.Colors.white,),
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

  ///конвертировать Offset в PdfPoint
  List<PdfPoint> convertPointsType(List<Offset> points){
    List<PdfPoint> result = [];
    points.forEach((e) {
      result.add(PdfPoint(e.dx, e.dy));
    });
    return result;
  }
}