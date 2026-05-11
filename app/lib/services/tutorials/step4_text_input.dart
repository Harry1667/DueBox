import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import '../logger_service.dart';
import 'tutorial_keys.dart';

TargetFocus createStep4TextInput(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return TargetFocus(
    identify: "Step 4: Text Input",
    keyTarget: TutorialKeys().textInputKey,
    alignSkip: Alignment.topRight,
    contents: [
      TargetContent(
        align: ContentAlign.top,
        builder: (context, controller) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.tutorialStep4Title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 10),
              Text(loc.tutorialStep4Desc, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          );
        },
      ),
    ],
    shape: ShapeLightFocus.RRect,
    enableOverlayTab: true,
    enableTargetTab: true,
  );
}
