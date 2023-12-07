import 'dart:ui';

///класс описывающий закладку в документе
class BookMarkPDF{
  int page;
  Offset offset;
  BookMarkPDF({
    required this.page,
    required this.offset
});

  factory BookMarkPDF.fromMap(Map<String, dynamic> json)  => BookMarkPDF(
    page: json['page'],
    offset: Offset(json['offset']['x'],json['offset']['y'])
  );


  Map<String, dynamic> toMap() => {
    "page" : page,
    "offset": {'x': offset.dx, 'y': offset.dy},
  };

}