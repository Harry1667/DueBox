import 'package:flutter/material.dart';

class TutorialKeys {
  static final TutorialKeys _instance = TutorialKeys._internal();
  factory TutorialKeys() => _instance;
  TutorialKeys._internal();

  final GlobalKey billListKey = GlobalKey();
  final GlobalKey titleKey = GlobalKey();
  final GlobalKey fabKey = GlobalKey();
  final GlobalKey menuKey = GlobalKey();
  final GlobalKey textInputKey = GlobalKey();
  final GlobalKey galleryInputKey = GlobalKey();
  final GlobalKey cameraInputKey = GlobalKey();
  final GlobalKey firstBillKey = GlobalKey();
  final GlobalKey editDialogKey = GlobalKey();
}
