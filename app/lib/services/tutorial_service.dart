import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'logger_service.dart';
import 'tutorials/tutorial_keys.dart';
import 'tutorials/step1_add_button.dart';
import 'tutorials/step3_menu_area.dart';
import 'tutorials/step4_text_input.dart';
import 'tutorials/step5_gallery_input.dart';
import 'tutorials/step6_camera_input.dart';
import 'tutorials/step7_start_record.dart';
import 'tutorials/step8_first_bill.dart';
import 'tutorials/step9_edit_bill.dart';
import 'tutorials/step10_finish.dart';

class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  TutorialCoachMark? tutorialCoachMark;
  
  bool _isTutorialActive = false;
  bool get isTutorialActive => _isTutorialActive;
  set isTutorialActive(bool value) {
    if (_isTutorialActive != value) {
      LoggerService().log("TutorialService: isTutorialActive changed from $_isTutorialActive to $value");
    }
    _isTutorialActive = value;
  }
  
  // Method to check if tutorial should show
  Future<bool> shouldShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('has_shown_tutorial_v2') ?? false);
  }

  // Method to mark tutorial as shown
  Future<void> completeTutorial() async {
    LoggerService().log("TutorialService: completeTutorial() called. Marking v2 as shown.");
    isTutorialActive = false; // Reset flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_tutorial_v2', true);
  }

  // Debug: Reset tutorial
  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_shown_tutorial_v2');
  }

  // Keys for Tutorial Targets (Centralized)
  GlobalKey get billListKey => TutorialKeys().billListKey;
  GlobalKey get titleKey => TutorialKeys().titleKey;
  GlobalKey get fabKey => TutorialKeys().fabKey;
  GlobalKey get menuKey => TutorialKeys().menuKey;
  GlobalKey get textInputKey => TutorialKeys().textInputKey;
  GlobalKey get galleryInputKey => TutorialKeys().galleryInputKey;
  GlobalKey get cameraInputKey => TutorialKeys().cameraInputKey;
  GlobalKey get firstBillKey => TutorialKeys().firstBillKey;
  GlobalKey get editDialogKey => TutorialKeys().editDialogKey;

  void startTutorial(BuildContext context, {required Function onOpenMenu}) {
    LoggerService().log("TutorialService: Starting Tutorial at Add Button Step");
    isTutorialActive = true; 

    List<TargetFocus> targets = [];
    targets.add(createStep1AddButton(context));

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.85),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.85,
      beforeFocus: (target) {
        LoggerService().log("Tutorial Step Start: ${target.identify}");
      },
      onClickTarget: (target) {
         LoggerService().log("Tutorial Step End: ${target.identify} (Target Clicked)");
         if (target.identify == "Step 1: Add Button") {
           tutorialCoachMark?.finish();
           Future.delayed(const Duration(milliseconds: 300), () {
             onOpenMenu(); 
             Future.delayed(const Duration(milliseconds: 600), () {
               _startTutorialPart2(context);
             });
           });
        }
      },
      onClickOverlay: (target) {
         LoggerService().log("Tutorial Step End: ${target.identify} (Overlay Clicked)");
         if (target.identify == "Step 1: Add Button") {
           tutorialCoachMark?.finish();
           Future.delayed(const Duration(milliseconds: 300), () {
             onOpenMenu(); 
             Future.delayed(const Duration(milliseconds: 600), () {
               _startTutorialPart2(context);
             });
           });
        }
      },
      onSkip: () {
        LoggerService().log("Tutorial Step Skip at: Step 1: Add Button");
        completeTutorial();
        return true;
      },
    );

    tutorialCoachMark?.show(context: context);
  }

  void _startTutorialPart2(BuildContext context) {
    LoggerService().log("TutorialService: Starting Part 2 (Steps 3-6)");
    if (menuKey.currentContext == null) {
       LoggerService().log("Menu Key context is null. Retrying in 500ms...");
       Future.delayed(const Duration(milliseconds: 500), () {
         _startTutorialPart2(context);
       });
       return;
    }

    List<TargetFocus> targets = [];
    targets.add(createStep3MenuArea(context));
    targets.add(createStep4TextInput(context));
    targets.add(createStep5GalleryInput(context));
    targets.add(createStep6CameraInput(context));

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.85),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.85,
      beforeFocus: (target) {
        LoggerService().log("Tutorial Step Start: ${target.identify}");
      },
      onFinish: () {
        LoggerService().log("Tutorial Part 2 Finished (Steps 3-6)");
        Future.delayed(const Duration(milliseconds: 300), () {
            _startStep7(context);
        });
      },
      onClickTarget: (target) {
          LoggerService().log("Tutorial Step End: ${target.identify} (Target Clicked)");
      },
      onClickOverlay: (target) {
          LoggerService().log("Tutorial Step End: ${target.identify} (Overlay Clicked)");
      },
      onSkip: () {
        LoggerService().log("Tutorial Part 2 Skipped");
        completeTutorial();
        return true;
      },
    );

    tutorialCoachMark?.show(context: context);
  }

  void _startStep7(BuildContext context) {
    LoggerService().log("TutorialService: Starting Step 7 (Click to start)");
    if (menuKey.currentContext == null) return;
    
    List<TargetFocus> targets = [];
    targets.add(createStep7StartRecord(context));

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.85),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.85,
      beforeFocus: (target) {
        LoggerService().log("Tutorial Step Start: ${target.identify}");
      },
      onClickOverlay: (target) {
         LoggerService().log("Tutorial Step End: Step 7: Start Record (Overlay Clicked)");
         stop(); 
      },
      onSkip: () {
         LoggerService().log("Tutorial Step Skip: Step 7: Start Record");
         stop();
         completeTutorial();
         return true;
      },
    );
    tutorialCoachMark?.show(context: context);
  }

  void stop() {
    LoggerService().log("TutorialService: stop() called. Terminating tutorial.");
    tutorialCoachMark?.finish();
    isTutorialActive = false; 
  }
  
  void stopForInteraction() {
      LoggerService().log("TutorialService: stopForInteraction() called. Keeping state true.");
      tutorialCoachMark?.finish(); 
  }

  void startStep8(BuildContext context, {required Function onOpenEdit}) {
      LoggerService().log("TutorialService: startStep8 called. firstBillKey context? ${firstBillKey.currentContext != null}");
      isTutorialActive = true; 
      if (firstBillKey.currentContext == null) {
          LoggerService().log("ERROR: First Bill Key context is null. Aborting Step 8.");
          return;
      }
      
      List<TargetFocus> targets = [];
      targets.add(createStep8FirstBill(context));

      tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        colorShadow: Colors.black.withOpacity(0.85),
        textSkip: "SKIP",
         paddingFocus: 10,
        opacityShadow: 0.85,
        beforeFocus: (target) {
          LoggerService().log("Tutorial Step Start: ${target.identify}");
        },
        onClickTarget: (target) {
           LoggerService().log("Tutorial Step End: Step 8: First Bill (Target Clicked)");
           tutorialCoachMark?.finish();
           Future.delayed(const Duration(milliseconds: 400), () {
               onOpenEdit(); 
           });
        },
        onClickOverlay: (target) {
            LoggerService().log("Tutorial Step End: Step 8: First Bill (Overlay Clicked)");
           tutorialCoachMark?.finish();
           Future.delayed(const Duration(milliseconds: 400), () {
               onOpenEdit(); 
           });
        },
        onSkip: () {
          LoggerService().log("Tutorial Step Skip: Step 8: First Bill");
          completeTutorial();
          return true;
        },
      );
      tutorialCoachMark?.show(context: context);
  }

  void startStep9(BuildContext context, {VoidCallback? onNext}) {
       LoggerService().log("TutorialService: startStep9 called.");
       isTutorialActive = true;

       int retries = 0;
       const int maxRetries = 15; 

       void tryStart() {
          if (editDialogKey.currentContext != null) {
              LoggerService().log("DEBUG: Edit Dialog Key found. Starting Step 9.");
              
              List<TargetFocus> targets = [];
              targets.add(createStep9EditBill(context));

              tutorialCoachMark = TutorialCoachMark(
                targets: targets,
                colorShadow: Colors.black.withOpacity(0.85),
                textSkip: "SKIP",
                paddingFocus: 10,
                opacityShadow: 0.85,
                beforeFocus: (target) {
                  LoggerService().log("Tutorial Step Start: ${target.identify}");
                },
                onFinish: () {
                   LoggerService().log("Tutorial Step End: Step 9: Edit Bill (Finished)");
                   Navigator.of(context).pop(); 
                   if (onNext != null) {
                      onNext();
                   } else {
                      startStep10(context);
                   }
                },
                onClickTarget: (target) {
                   LoggerService().log("Tutorial Step End: Step 9: Edit Bill (Target Clicked)");
                   tutorialCoachMark?.finish(); 
                },
                onClickOverlay: (target) {
                   LoggerService().log("Tutorial Step End: Step 9: Edit Bill (Overlay Clicked)");
                   tutorialCoachMark?.finish(); 
                },
                onSkip: () {
                   LoggerService().log("Tutorial Step Skip: Step 9: Edit Bill");
                   completeTutorial();
                   return true;
                },
              );
              tutorialCoachMark?.show(context: context);
          } else {
             if (retries < maxRetries) {
                retries++;
                Future.delayed(const Duration(milliseconds: 300), tryStart);
             } else {
                LoggerService().log("ERROR: Edit Dialog Key never appeared for Step 9.");
             }
          }
       }
       tryStart();
  }

  void startStep10(BuildContext context) {
       LoggerService().log("TutorialService: Starting Step 10 (Finish)");
       List<TargetFocus> targets = [];
       targets.add(createStep10Finish(context));
        
      tutorialCoachMark = TutorialCoachMark(
          targets: targets,
          colorShadow: Colors.black.withOpacity(0.85),
          beforeFocus: (target) {
            LoggerService().log("Tutorial Step Start: ${target.identify}");
          },
          onFinish: () {
             LoggerService().log("Tutorial Step End: Step 10: Finish (Finished)");
             completeTutorial();
          },
          onClickOverlay: (target) {
             LoggerService().log("Tutorial Step End: Step 10: Finish (Overlay Clicked)");
             completeTutorial();
          },
          onClickTarget: (target) {
             LoggerService().log("Tutorial Step End: Step 10: Finish (Target Clicked)");
             completeTutorial();
          }
      );
      tutorialCoachMark?.show(context: context);
  }
}
