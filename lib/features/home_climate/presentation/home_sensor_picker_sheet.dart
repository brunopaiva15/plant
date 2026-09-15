import 'package:flutter/cupertino.dart';

import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/home/home_climate.dart';
import 'home_climate_widgets.dart';

/// Le choix d'un capteur pour une grandeur : la plateforme d'abord, quand
/// l'appareil lit les deux maisons, puis la maison quand il y en a
/// plusieurs, puis les accessoires de cette maison qui mesurent la grandeur,
/// pièce par pièce, avec ce que chacun sait mesurer. Rend le capteur choisi,
/// ou `null` si la feuille se referme.
Future<HomeSensor?> showHomeSensorPicker(BuildContext context, {required List<HomeSensor> sensors, required HomeQuantity quantity, String? selectedKey}) {
  return showFloraSheet<HomeSensor>(
    context,
    scrollable: true,
    builder: (ctx) => _HomeSensorPickerBody(sensors: [for (final s in sensors) if (s.measures(quantity)) s], quantity: quantity, selectedKey: selectedKey),
  );
}

/// Quelle maison brancher, quand l'appareil lit les deux.
///
/// Une demande d'accès à la fois : les enchaîner sans rien dire poserait
/// deux questions du système coup sur coup, et personne ne saurait laquelle
/// il vient de refuser. Rend la maison choisie, ou `null` si la feuille se
/// referme.
Future<HomeSource?> showHomeSourcePicker(BuildContext context, {required List<HomeSource> sources}) {
  return showFloraSheet<HomeSource>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: ctx.l10n.homeClimateSource),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
          child: FloraGroup(
            children: [
              for (final source in sources)
                FloraListRow(
                  leading: const Text('🏠', style: TextStyle(fontSize: 18)),
                  title: homeSourceLabel(ctx.l10n, source),
                  onTap: () => Navigator.of(ctx).pop(source),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HomeSensorPickerBody extends StatefulWidget {
  const _HomeSensorPickerBody({required this.sensors, required this.quantity, required this.selectedKey});

  final List<HomeSensor> sensors;
  final HomeQuantity quantity;
  final String? selectedKey;

  @override
  State<_HomeSensorPickerBody> createState() => _HomeSensorPickerBodyState();
}

class _HomeSensorPickerBodyState extends State<_HomeSensorPickerBody> {
  late HomeSource? _source = _initialSource();
  late String? _home = _initialHome();

  /// Le capteur déjà retenu, s'il est dans la liste.
  HomeSensor? get _current => widget.sensors.where((s) => s.key == widget.selectedKey).firstOrNull;

  /// Les plateformes qui ont donné un capteur, dans l'ordre où elles l'ont
  /// donné.
  List<HomeSource> get _sources {
    final out = <HomeSource>[];
    for (final s in widget.sensors) {
      if (!out.contains(s.source)) out.add(s.source);
    }
    return out;
  }

  /// La plateforme du capteur déjà retenu, sinon la première.
  HomeSource? _initialSource() => _current?.source ?? _sources.firstOrNull;

  /// La maison du capteur déjà retenu, sinon la première de la plateforme.
  String? _initialHome() {
    if (_current case final current? when current.source == _source) return current.homeName ?? '';
    return _homes(_source).firstOrNull;
  }

  /// Les maisons d'une plateforme, dans l'ordre où elle les donne ; sans
  /// nom, une seule entrée vide les rassemble.
  List<String> _homes(HomeSource? source) {
    final out = <String>[];
    for (final s in widget.sensors) {
      if (s.source != source) continue;
      final h = s.homeName ?? '';
      if (!out.contains(h)) out.add(h);
    }
    return out;
  }

  /// Changer de plateforme change de maisons : celle qui était retenue n'est
  /// pas la sienne.
  void _pickSource(HomeSource source) => setState(() {
        _source = source;
        _home = _homes(source).firstOrNull ?? '';
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final sources = _sources;
    final homes = _homes(_source);
    final inHome = [
      for (final s in widget.sensors)
        if (s.source == _source && (s.homeName ?? '') == (_home ?? '')) s,
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
              // Apple Maison et Google Home peuvent nommer leurs maisons de
              // la même façon : la plateforme se choisit avant elles.
              if (sources.length > 1) ...[
                Text(l10n.homeClimateSource, style: context.text.caption),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.xs,
                  runSpacing: Space.xs,
                  children: [
                    for (final s in sources) FloraChip(label: homeSourceLabel(l10n, s), emoji: '🏠', selected: s == _source, onTap: () => _pickSource(s)),
                  ],
                ),
                const SizedBox(height: Space.lg),
              ],
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
                          leading: Text(widget.quantity == HomeQuantity.temperature ? '🌡️' : '💧', style: const TextStyle(fontSize: 18)),
                          title: s.name,
                          subtitle: measuresLabel(l10n, s),
                          trailing: s.key == widget.selectedKey ? Icon(CupertinoIcons.checkmark_circle_fill, color: c.sage) : null,
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
