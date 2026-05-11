import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import '../logger_service.dart';
import 'tutorial_keys.dart';

TargetFocus createStep9EditBill(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return TargetFocus(
    identify: "Step 9: Edit Bill",
    keyTarget: TutorialKeys().editDialogKey,
    alignSkip: Alignment.topRight,
    contents: [
      TargetContent(
        align: ContentAlign.custom,
        customPosition: CustomTargetContentPosition(
          bottom: 120,
          left: 20,
          right: 20,
        ),
        builder: (context, controller) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(loc.tutorialStep9Title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 10),
              Text(loc.tutorialStep9Desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          );
        },
      ),
    ],
    shape: ShapeLightFocus.RRect,
    radius: 28,
    enableOverlayTab: true,
    enableTargetTab: true,
  );
}
