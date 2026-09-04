import 'package:flutter/painting.dart';

abstract final class Radii {
  static const double small = 10;
  static const double medium = 16;
  static const double large = 24;
  static const double xl = 32;
  static const double full = 999;

  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumAll = BorderRadius.all(Radius.circular(medium));
  static const BorderRadius largeAll = BorderRadius.all(Radius.circular(large));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(xl));
}
