import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les quatre langues de l'application, côté iOS.
///
/// `CFBundleLocalizations` ne suffit pas : l'App Store lit les langues dans
/// les dossiers `.lproj` du paquet. Avec le seul `Base.lproj`, la fiche
/// annonçait « Anglais » et rien d'autre. Chaque langue a donc son
/// `InfoPlist.strings`, qui traduit aussi les demandes d'autorisation.
void main() {
  const locales = ['fr', 'en', 'de', 'it'];
  final plist = File('ios/Runner/Info.plist').readAsStringSync();

  final usageKeys = RegExp(r'<key>(NS\w+UsageDescription)</key>')
      .allMatches(plist)
      .map((m) => m.group(1)!)
      .toSet();

  Set<String> keysOf(String locale) {
    final text =
        File('ios/Runner/$locale.lproj/InfoPlist.strings').readAsStringSync();
    return RegExp(r'^"(\w+)" = "[^"]+";$', multiLine: true)
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();
  }

  test('Info.plist déclare les quatre langues', () {
    for (final locale in locales) {
      expect(plist, contains('<string>$locale</string>'), reason: locale);
    }
  });

  test("chaque langue traduit chaque demande d'autorisation", () {
    expect(usageKeys, isNotEmpty);
    for (final locale in locales) {
      expect(keysOf(locale), usageKeys, reason: locale);
    }
  });

  test('le projet Xcode embarque les quatre InfoPlist.strings', () {
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(project, contains('InfoPlist.strings in Resources'));
    for (final locale in locales) {
      expect(project, contains('path = $locale.lproj/InfoPlist.strings;'),
          reason: locale);
    }
  });
}
