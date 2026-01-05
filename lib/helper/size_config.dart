import 'package:flutter/material.dart';

class SizeConfig {
  static MediaQueryData? _mediaQueryData;
  static double? screenWidth;
  static double? screenHeight;
  static double? blockSizeHorizontal;
  static double? blockSizeVertical;

  //web sizing.
  static double? subText;
  static double? smallSubText;
  static double? smallTitleText;
  static double? titleText;
  static double? medbigText;
  static double? bigText;
  static double? heightAndWidth;
  static double? bigHeightAndWidth;
  static double? maxHeightAndWidth;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData!.size.width;
    screenHeight = _mediaQueryData!.size.height;
    blockSizeHorizontal = screenWidth! / 100;
    blockSizeVertical = screenHeight! / 100;

    //web sizing
    subText = 15;
    smallSubText = 13;
    smallTitleText = 17;
    titleText = 19;
    medbigText = 21;
    bigText = 27;
    heightAndWidth = 10;
    bigHeightAndWidth = 15;
    maxHeightAndWidth = 20;
  }
}