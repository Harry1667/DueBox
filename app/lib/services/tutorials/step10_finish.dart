import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import '../logger_service.dart';
import 'tutorial_keys.dart';

TargetFocus createStep10Finish(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return TargetFocus(
    identify: "Step 10: Finish",
    keyTarget: TutorialKeys().billListKey,
    contents: [
      TargetContent(
        align: ContentAlign.custom,
        customPosition: CustomTargetContentPosition(top: MediaQuery.of(context).size.height / 2 - 100, left: 20, right: 20),
        builder: (context, controller) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 60),
                const SizedBox(height: 16),
                Text(loc.tutorialFinishTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                const SizedBox(height: 10),
                Text(loc.tutorialFinishDesc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          );
        },
      ),
    ],
    shape: ShapeLightFocus.RRect,
    enableOverlayTab: true,
    enableTargetTab: true,
  );
}
