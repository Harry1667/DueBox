import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import '../logger_service.dart';
import 'tutorial_keys.dart';

TargetFocus createStep1AddButton(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return TargetFocus(
    identify: "Step 1: Add Button",
    keyTarget: TutorialKeys().fabKey,
    alignSkip: Alignment.topRight,
    contents: [
      TargetContent(
        align: ContentAlign.top,
        builder: (context, controller) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tutorialStep2Title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 10),
              Text(
                loc.tutorialStep2Desc,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          );
        },
      ),
    ],
    shape: ShapeLightFocus.Circle,
    enableOverlayTab: true,
    enableTargetTab: true,
  );
}
