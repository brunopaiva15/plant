import 'package:flutter/cupertino.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/home/home_climate.dart';

/// Le choix d'un capteur pour une grandeur : la maison d'abord, quand il y
/// en a plusieurs, puis les accessoires de cette maison qui la mesurent,
/// pièce par pièce, avec ce que chacun sait mesurer. Rend le capteur choisi,
/// ou `null` si la feuille se referme.
Future<HomeSensor?> showHomeSensorPicker(BuildContext context, {required List<HomeSensor> sensors, required HomeQuantity quantity, String? selectedId}) {
  return showFloraSheet<HomeSensor>(
    context,
    scrollable: true,
    builder: (ctx) => _HomeSensorPickerBody(sensors: [for (final s in sensors) if (s.measures(quantity)) s], quantity: quantity, selectedId: selectedId),
  );
}

class _HomeSensorPickerBody extends StatefulWidget {
  const _HomeSensorPickerBody({required this.sensors, required this.quantity, required this.selectedId});

  final List<HomeSensor> sensors;
  final HomeQuantity quantity;
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
        SheetHeader(title: widget.quantity == HomeQuantity.temperature ? l10n.homeClimateTemperatureSensor : l10n.homeClimateHumiditySensor),
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
              // Ce que HomeKit ne donne pas — les HomePod — peut venir d'un
              // raccourci, quel que soit le capteur derrière.
              FloraGroup(
                header: l10n.homeClimateOtherSource,
                children: [
                  FloraListRow(
                    leading: const Text('⚡️', style: TextStyle(fontSize: 18)),
                    title: l10n.homeClimateShortcut,
                    subtitle: l10n.homeClimateShortcutSubtitle,
                    trailing: widget.selectedId == HomeSensor.shortcutId ? Icon(CupertinoIcons.checkmark_circle_fill, color: c.sage) : null,
                    chevron: false,
                    onTap: () => Navigator.of(context).pop(HomeSensor(id: HomeSensor.shortcutId, name: l10n.homeClimateShortcut)),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              for (final room in rooms) ...[
                FloraGroup(
                  header: room ?? l10n.homeClimateNoRoom,
                  children: [
                    for (final s in inHome)
                      if (s.roomName == room)
                        FloraListRow(
                          leading: Text(widget.quantity == HomeQuantity.temperature ? '🌡️' : '💧', style: const TextStyle(fontSize: 18)),
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
