import 'dart:convert';
import 'dart:io';

import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/identification/presentation/identification_photos.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// La bande des photos d'identification.
///
/// Ce qu'elle doit dire sans phrase : *on peut en prendre plusieurs*. Toute
/// la valeur du composant tient dans la case vide — c'est elle, et non un
/// bouton au singulier, qui laisse deviner la suite. Ces tests gardent donc
/// trois choses : la place libre n'apparaît que si l'on peut la remplir, elle
/// ne s'offre qu'une fois à la fois, et la première photo — celle de
/// l'appelant — n'a pas de croix.

/// Un vrai fichier, pour que `Image.file` n'ait rien à signaler : un PNG de
/// un pixel suffit, le décodage n'ayant pas lieu dans un banc d'essai.
String _png() {
  final dir = Directory.systemTemp.createTempSync('strip');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}/p.png')
    ..writeAsBytesSync(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));
  return file.path;
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildFloraTheme(Brightness.light),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('une photo, et la place qui reste se voit', (tester) async {
    await tester.pumpWidget(_app(IdentificationPhotoStrip(
      paths: [_png()],
      maxPhotos: 3,
      onAdd: () {},
    )));

    // Trois emplacements dessinés pour une seule photo : c'est là tout le
    // propos. Un seul écoute le doigt — la première case libre ; celle
    // d'après n'est que la place qui reste.
    expect(find.byType(Pressable), findsOneWidget);
  });

  testWidgets("sans invitation, la bande se tait sur ce qu'elle ne peut pas offrir", (tester) async {
    await tester.pumpWidget(_app(IdentificationPhotoStrip(
      paths: [_png(), _png()],
      maxPhotos: 3,
      onRemove: (_) {},
    )));

    // `onAdd` nul — une réponse venue de Pl@ntNet —, donc aucune case libre
    // et aucun déclencheur : seule la croix de la deuxième photo écoute.
    expect(find.byType(Pressable), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.camera_fill), findsNothing);
  });

  testWidgets('la photo de l’appelant ne se retire pas, les autres si', (tester) async {
    final retirees = <int>[];
    await tester.pumpWidget(_app(IdentificationPhotoStrip(
      paths: [_png(), _png(), _png()],
      maxPhotos: 3,
      onRemove: retirees.add,
    )));

    // Trois photos, deux croix : le rang zéro appartient à l'appelant.
    expect(find.byIcon(CupertinoIcons.xmark), findsNWidgets(2));

    await tester.tap(find.byIcon(CupertinoIcons.xmark).first);
    expect(retirees, [1], reason: 'la croix rend le rang de sa photo, pas le sien');
  });

  testWidgets('la bande pleine ne propose plus rien', (tester) async {
    await tester.pumpWidget(_app(IdentificationPhotoStrip(
      paths: [_png(), _png(), _png()],
      maxPhotos: 3,
      onAdd: () {},
    )));

    expect(find.byIcon(CupertinoIcons.camera_fill), findsNothing);
  });
}
