
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
  String? uuid;
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
  List<PdfPoint> points;

  ///виджет аннотации для инбекции его в документ
  pw.Widget get child => setAnnotationWidget();
  ///виджет аннотации для формирования дерева виджетов во внутреннем просмотрщике и создания кликабельности по аннотации
  Material.Widget tapChild = Material.Container();

  double aspectCoefY = 1;
  double aspectCoefX = 1;


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
    this.uuid
  }){
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

    points.forEach((e) {
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
      ///видимо придется использовать множество полилайн с подстановкой цветов, толщины и массива точек
      case AnnotationType.polyLineAnnotation : {
        result =
           pw.Opacity(
            child:
            pw.PolyLineAnnotation(
            points: points ?? [],
            color: color,
            author: author,
            date: date,
            subject: subject,
            content: content
        ),
            opacity: subject == 'selectText' ? 0.3 : 1
        );
        break;
      }
      case AnnotationType.inkAnnotation : {
        result = pw.Opacity(
          child: pw.InkAnnotation(
              points: [],
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
                  value: subject,
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
    if( points.isNotEmpty){
      _points = points;
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
        top: (top * aspectCoefY) - border!.width,
        left: left * aspectCoefX,
        child: Material.Container(
            height: subject == 'selectText' ? border!.width * 2 : height * aspectCoefX,
            width: width * aspectCoefX,
            //color: widgetTaped ? Material.Colors.red.withOpacity(0.5) : Material.Colors.green.withOpacity(0.5)
            alignment: Material.Alignment.topRight,
            //color: Material.Colors.red.withOpacity(0.3),
              child: points.isNotEmpty && subject == 'selectText' ? Material.GestureDetector(
                onTap: (){

                  /// если аннотация была текстом, переходим к редактированию ее контента
                  final FocusNode myFocusNode1 = FocusNode();
                  void _requestFocus1(){
                    setState(() {
                      //FocusScope.of(context).requestFocus(myFocusNode1);
                    });
                  }

                  final TextEditingController controller = TextEditingController(text: content);

                  const Material.OutlineInputBorder border = Material.OutlineInputBorder(
                      borderRadius: Material.BorderRadius.all(Material.Radius.circular(7.0)),
                      borderSide: Material.BorderSide(color: Material.Colors.white, width: 2));
                  const Material.BoxConstraints constraints = Material.BoxConstraints(minWidth: 40.0, minHeight: 40.0, maxWidth: 40.0, maxHeight: 40.0);


                  Material.showDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierColor: Material.Colors.transparent,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Material.AlertDialog(
                            scrollable: true,
                            backgroundColor: Material.Colors.transparent,
                            contentPadding: const Material.EdgeInsets.fromLTRB(0, 0, 30, 0),
                            insetPadding: const Material.EdgeInsets.all(10),
                            elevation: 0.0,
                            content: Material.Container(
                              padding: const Material.EdgeInsets.fromLTRB(0,10,0,10),
                              constraints: const Material.BoxConstraints(
                                minWidth: 200,
                                maxWidth: 320,
                              ),
                              decoration:  Material.BoxDecoration(
                                color: Material.Color(0xFF0B1730),
                                border: Material.Border.all(color: Material.Colors.white),
                                borderRadius: const Material.BorderRadius.only(
                                  topRight: Material.Radius.circular(11.0),
                                  topLeft: Material.Radius.circular(11.0),
                                  bottomRight: Material.Radius.circular(11.0),
                                  bottomLeft: Material.Radius.circular(11.0),
                                ),
                              ),
                              child:  Material.Column(
                                mainAxisSize: Material.MainAxisSize.min,
                                children: <Material.Widget>[
                                  Material.Container(
                                      margin: const Material.EdgeInsets.fromLTRB(10,10,10,0),
                                      padding: const Material.EdgeInsets.fromLTRB(0,0,0,0),
                                      alignment: Material.Alignment.topCenter,
                                      width: MediaQuery.of(context).size.width - 40,
                                      height: 200,
                                      child:Material.TextFormField(
                                        autofocus: true,
                                        maxLines: 15, minLines: 15, expands: false,
                                        maxLength: 1000,
                                        onTap: _requestFocus1,
                                        focusNode: myFocusNode1,
                                        textAlign: Material.TextAlign.left,
                                        enabled: true,
                                        keyboardType: TextInputType.streetAddress,
                                        decoration: const Material.InputDecoration(
                                          contentPadding: Material.EdgeInsets.only(
                                              left: 15,
                                              top: 10,
                                              bottom: 10
                                          ),
                                          counter: Material.SizedBox.shrink(),
                                          hintText: 'Комментарий',
                                          border: border,
                                          focusedBorder: border,
                                          enabledBorder: border,
                                          errorBorder: border,
                                          labelText: 'Комментарий',
                                          labelStyle: Material.TextStyle(fontSize: 15.0, color: Material.Colors.white,fontFamily: 'Inter'),
                                        ),
                                        onChanged: (_){setState(() {});},
                                        autovalidateMode: AutovalidateMode.always,
                                        controller: controller,
                                      )),
                                  Material.Row(
                                    mainAxisAlignment: Material.MainAxisAlignment.center,
                                    children: [
                                      Material.RawMaterialButton(
                                        constraints: constraints,
                                        onPressed: (){
                                          //e.content = '';
                                          Navigator.of(context).pop();
                                        },
                                        elevation: 2.0,
                                        fillColor: Material.Colors.transparent,
                                        padding: const Material.EdgeInsets.all(5.0),
                                        shape: const CircleBorder(),
                                        child: const Material.Icon(CupertinoIcons.clear, color: Material.Colors.white,),
                                      ),
                                      Material.RawMaterialButton(
                                        constraints: constraints,
                                        onPressed: (){
                                          content = controller.text;
                                          Navigator.of(context).pop();
                                        },
                                        elevation: 2.0,
                                        fillColor: Material.Colors.transparent,
                                        padding: const Material.EdgeInsets.all(5.0),
                                        shape: const CircleBorder(),
                                        child: const Material.Icon(CupertinoIcons.check_mark, color: Material.Colors.white,),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          );},
                      );
                    },
                  ).then((value)=>setState((){}));
                },
                child: Material.Icon(Material.Icons.announcement_sharp, color: Material.Colors.orange,),
          ) : null,
          ),
       // ),
      );
    });
  }

  factory AnnotationItem.fromMap(Map<String, dynamic> json)  => AnnotationItem(
    uuid: json['uuid'],
    page: json['page'] ?? 0,
    annotationType: AnnotationType.values.firstWhere((e) => e.name == json['annotationType']),
    color: PdfColor.fromHex(json['color']),
    border: PdfBorder(PdfDocument(), json['border']),
    author: json['author'],
    date: DateTime.fromMillisecondsSinceEpoch(json['date']),
    content: json['content'],
    subject: json['subject'],
    points: (json['points'] as List).map((e) => PdfPoint(e['x'], e['y'])).toList().cast<PdfPoint>(),
  );


  Map<String, dynamic> toMap() => {
    "uuid" : uuid,
    "page": page,
    "annotationType": annotationType.name,
    "color": color!.toHex(),
    "border": border!.width,
    "author": author,
    "date": date!.millisecondsSinceEpoch,
    "content": content,
    "subject": subject,
    "points": points.map((e) => {'x' : e.x, 'y': e.y}).toList(),
  };

  ///конвертировать Offset в PdfPoint
  List<PdfPoint> convertPointsType(List<Offset> points){
    List<PdfPoint> result = [];
    points.forEach((e) {
      result.add(PdfPoint(e.dx, e.dy));
    });
    print('набрали точек ${result.length}, страница $page');
    return result;
  }
}