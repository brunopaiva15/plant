import 'dart:convert';
import 'dart:io';

import 'package:flora/app/providers.dart';
import 'package:flora/data/services/photo_storage_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/features/plants/presentation/photo_picker_sheet.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Choisir une photo en la regardant : une vignette par photo, la retenue
/// marquée, et la touchée rendue.

class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePaths(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

PlantPhoto _photo(String id, DateTime takenAt) => PlantPhoto(
      id: id,
      plantId: 'p1',
      filePath: '$id.jpg',
      thumbPath: '${id}_thumb.jpg',
      width: 1,
      height: 1,
      takenAt: takenAt,
      createdAt: takenAt,
    );

void main() {
  late Directory temp;
  final photos = [_photo('c', DateTime(2026, 8, 1)), _photo('b', DateTime(2026, 6, 1)), _photo('a', DateTime(2026, 3, 1))];

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('flora-picker');
    PathProviderPlatform.instance = _FakePaths(temp.path);
    final dir = Directory('${temp.path}/photos')..createSync(recursive: true);
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
    for (final p in photos) {
      File('${dir.path}/${p.thumbPath}').writeAsBytesSync(png);
    }
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  testWidgets('une vignette par photo, la retenue marquée, la touchée rendue', (tester) async {
    PlantPhoto? picked;
    await tester.pumpWidget(ProviderScope(
      overrides: [photoStorageProvider.overrideWithValue(PhotoStorageService())],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async => picked = await showPhotoPickerSheet(context, title: 'Avant', photos: photos, selectedId: 'a'),
                child: const Text('choisir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('choisir'));
    await tester.pumpAndSettle();

    expect(find.text('Avant'), findsOneWidget);
    expect(find.byType(PlantImage), findsNWidgets(3));
    // Une seule coche : celle de la photo déjà retenue.
    expect(find.byIcon(CupertinoIcons.checkmark), findsOneWidget);

    await tester.tap(find.text('1 juin'));
    await tester.pumpAndSettle();
    expect(picked?.id, 'b');
    expect(find.byType(PlantImage), findsNothing, reason: 'la sheet se referme sur le choix');
  });
}
