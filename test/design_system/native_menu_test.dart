import 'package:flora/core/native_shell.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce qu'un bouton déplie, et qui l'entend.
///
/// Sur iOS, les trois points de la fiche ne font plus monter une feuille du
/// bas : le système déplie un `UIMenu` à leur place. Les entrées partent donc
/// avec le bouton, et le natif renvoie l'entrée choisie — `R0.1` —, pas le
/// bouton qui la portait. Ce test tient les deux bouts de ce fil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('ch.vergasta.plant/native_shell');

  setUp(() {
    NativeShell.debugForceSupported = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (call) async => true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(canal, null);
    NativeShell.debugReset();
  });

  FloraIconButton plus(List<SheetAction> menu, {VoidCallback? onPressed}) => FloraIconButton(
    icon: CupertinoIcons.ellipsis,
    semanticLabel: 'Plus',
    menu: menu,
    onPressed: onPressed ?? () {},
  );

  test('un bouton à menu se décrit entrée par entrée', () {
    final decrit = NativeActions.describe(const <Widget>[], <Widget>[
      plus([
        SheetAction(label: 'Modifier', icon: CupertinoIcons.pencil, onPressed: () {}),
        SheetAction(label: 'Archiver', icon: CupertinoIcons.archivebox, destructive: true, separated: true, onPressed: () {}),
      ]),
    ]);

    expect(decrit, isNotNull, reason: 'le bouton a son symbole, la barre reste au système');
    final menu = decrit!.actions.single.action.menu;
    expect(menu.map((m) => m.id).toList(), ['R0.0', 'R0.1']);
    expect(menu.map((m) => m.title).toList(), ['Modifier', 'Archiver']);
    expect(menu.first.symbol, 'pencil');
    expect(menu.last.destructive, isTrue);
    expect(menu.last.separated, isTrue, reason: 'iOS sépare ses groupes d\'un trait');
  });

  test('une entrée sans symbole ne rend pas la barre à Flutter', () {
    // Tout ou rien vaut pour les boutons de la barre, pas pour ce qu'ils
    // déplient : une entrée sans image reste une ligne de texte.
    final decrit = NativeActions.describe(const <Widget>[], <Widget>[
      plus([SheetAction(label: 'Sans image', onPressed: () {})]),
    ]);

    expect(decrit, isNotNull);
    expect(decrit!.actions.single.action.menu.single.symbol, isNull);
  });

  testWidgets('le natif renvoie l\'entrée choisie, pas le bouton', (tester) async {
    var choisi = '';
    final decrit = NativeActions.describe(const <Widget>[], <Widget>[
      plus(
        [
          SheetAction(label: 'Modifier', onPressed: () => choisi = 'modifier'),
          SheetAction(label: 'Archiver', onPressed: () => choisi = 'archiver'),
        ],
        onPressed: () => choisi = 'le bouton',
      ),
    ])!;

    await tester.pumpWidget(MaterialApp(
      home: NativeActions(title: '', leading: decrit.leading, actions: decrit.actions, child: const SizedBox.shrink()),
    ));

    NativeShell.onAction!('R0.1');
    expect(choisi, 'archiver');

    // Le bouton lui-même reste joignable : c'est lui qui répond là où le
    // système ne déplie rien.
    NativeShell.onAction!('R0');
    expect(choisi, 'le bouton');

    // Une entrée qui n'existe pas ne réveille personne.
    choisi = '';
    NativeShell.onAction!('R0.7');
    expect(choisi, '');
  });
}
