import 'dart:ui';

class MatchedItemMy {
  //Constructor
  MatchedItemMy({this.text, this.bounds, this.pageIndex});

  //Fields
  /// The searched text.
  String? text;

  /// Rectangle bounds of the searched text.
  Rect? bounds;

  /// Page number of the searched text.
  int? pageIndex;

}