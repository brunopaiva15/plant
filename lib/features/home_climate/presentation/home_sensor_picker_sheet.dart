import 'package:flutter/cupertino.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/home/home_climate.dart';

/// Le choix du capteur : la maison d'abord, quand il y en a plusieurs, puis
/// les accessoires de cette maison, pièce par pièce, avec ce que chacun
/// mesure. Rend le capteur choisi, ou `null` si la feuille se referme.
Future<HomeSensor?> showHomeSensorPicker(BuildContext context, {required List<HomeSensor> sensors, String? selectedId}) {
  return showFloraSheet<HomeSensor>(
    context,
    scrollable: true,
    builder: (ctx) => _HomeSensorPickerBody(sensors: sensors, selectedId: selectedId),
  );
}

class _HomeSensorPickerBody extends StatefulWidget {
  const _HomeSensorPickerBody({required this.sensors, required this.selectedId});

  final List<HomeSensor> sensors;
  final String? selectedId;

  @override
  State<_HomeSensorPickerBody> createState() => _HomeSensorPickerBodyState();
}

class _HomeSensorPickerBodyState extends State<_HomeSensorPickerBody> {
  late String? _home = _initialHome();

  /// Les maisons, dans l'ordre où HomeKit les donne ; sans nom, une seule
  /// entrée vide les rassemble.
  List<String> get _homes {
    final out = <String>[];
    for (final s in widget.sensors) {
      final h = s.homeName ?? '';
      if (!out.contains(h)) out.add(h);
    }
    return out;
  }

  /// La maison du capteur déjà retenu, sinon la première.
  String? _initialHome() {
    final homes = _homes;
    if (homes.length <= 1) return homes.firstOrNull;
    final current = widget.sensors.where((s) => s.id == widget.selectedId).firstOrNull;
    return current?.homeName ?? homes.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final homes = _homes;
    final inHome = [
      for (final s in widget.sensors)
        if ((s.homeName ?? '') == (_home ?? '')) s,
    ];
    // Les pièces dans l'ordre d'apparition, celles sans pièce à la fin.
    final rooms = <String?>[];
    for (final s in inHome) {
      final r = s.roomName;
      if (r != null && !rooms.contains(r)) rooms.add(r);
    }
    if (inHome.any((s) => s.roomName == null)) rooms.add(null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.homeClimateChoose),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (homes.length > 1) ...[
                Text(l10n.homeClimateHome, style: context.text.caption),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    for (final h in homes) FloraChip(label: h.isEmpty ? l10n.homeClimateHome : h, emoji: '🏠', selected: h == _home, onTap: () => setState(() => _home = h)),
                  ],
                ),
                const SizedBox(height: Space.lg),
              ],
              for (final room in rooms) ...[
                FloraGroup(
                  header: room ?? l10n.homeClimateNoRoom,
                  children: [
                    for (final s in inHome)
                      if (s.roomName == room)
                        FloraListRow(
                          leading: const Text('🌡️', style: TextStyle(fontSize: 18)),
                          title: s.name,
                          subtitle: measuresLabel(l10n, s),
                          trailing: s.id == widget.selectedId ? Icon(CupertinoIcons.checkmark_circle_fill, color: c.sage) : null,
                          chevron: false,
                          onTap: () => Navigator.of(context).pop(s),
                        ),
                  ],
                ),
                const SizedBox(height: Space.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// « Température · Humidité » : ce que l'accessoire sait mesurer.
String measuresLabel(AppLocalizations l10n, HomeSensor s) => [
      if (s.hasTemperature) l10n.careTemperature,
      if (s.hasHumidity) l10n.weatherHumidity,
    ].join(' · ');
