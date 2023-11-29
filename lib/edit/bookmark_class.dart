import 'dart:ui';

///класс описывающий закладку в документе
class BookMarkPDF{
  int page;
  Offset offset;
  BookMarkPDF({
    required this.page,
    required this.offset
});
}