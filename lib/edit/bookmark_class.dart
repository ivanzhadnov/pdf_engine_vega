import 'dart:ui';

///класс описывающий закладку в документе
class BookMarkPDF{
  int page;
  Offset offset;
  String content;
  BookMarkPDF({
    required this.page,
    required this.offset,
    this.content = ''
});

  factory BookMarkPDF.fromMap(Map<String, dynamic> json)  => BookMarkPDF(
    page: json['page'],
    offset: Offset(json['offset']['x'],json['offset']['y']),
    content: json['content'] ?? ''

  );


  Map<String, dynamic> toMap() => {
    "page" : page,
    "offset": {'x': offset.dx, 'y': offset.dy},
    "content" : content
  };

}