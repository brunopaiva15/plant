import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Le relais qui porte les boutons d'une page jusqu'au menu debout.
///
/// Quand le menu passe à droite ([FloraTabRail]), les boutons du haut de page
/// n'ont plus de raison de rester en haut : ils rejoignent la colonne, à la
/// suite des onglets. Seulement c'est la coquille qui dessine la colonne, et
/// chaque page qui connaît ses boutons — d'où ce relais.
///
/// Une page se déclare par [RailActions]. Plusieurs peuvent l'être en même
/// temps : les branches du shell restent montées quand on change d'onglet, et
/// une page poussée se pose par-dessus celle de sa branche. C'est la dernière
/// **visible** qui gagne, et la visibilité se lit au `TickerMode` que
/// go_router coupe sur les branches hors écran (`route.dart`, `Offstage` +
/// `TickerMode(enabled: isActive)`).
class RailActionsSlot extends ChangeNotifier {
  final List<_RailEntry> _entries = <_RailEntry>[];
  bool _scheduled = false;
  bool _disposed = false;

  /// Les boutons à poser sous les onglets. Vide quand aucune page n'en offre.
  List<Widget> get actions {
    for (final entry in _entries.reversed) {
      if (entry.visible && entry.actions.isNotEmpty) return entry.actions;
    }
    return const <Widget>[];
  }

  void _add(_RailEntry entry) {
    _entries.add(entry);
    _schedule();
  }

  void _remove(_RailEntry entry) {
    _entries.remove(entry);
    _schedule();
  }

  /// Remet une page au premier plan : c'est ce qui se passe quand on revient
  /// sur un onglet resté monté derrière.
  void _promote(_RailEntry entry) {
    if (_entries.isNotEmpty && !identical(_entries.last, entry)) {
      _entries
        ..remove(entry)
        ..add(entry);
    }
    _schedule();
  }

  /// La colonne se redessine après l'image, jamais pendant : la coquille est
  /// construite avant les pages, et la prévenir en cours de construction
  /// reviendrait à rebâtir un ancêtre déjà bâti. Une image de retard, que
  /// personne ne voit.
  void _schedule() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _RailEntry {
  _RailEntry(this.actions, this.visible);

  List<Widget> actions;
  bool visible;
}

/// Porte le relais jusqu'aux pages. Posé par la coquille, au-dessus du
/// contenu ; les pages qui n'en trouvent pas gardent leurs boutons en haut.
class RailActionsScope extends InheritedWidget {
  const RailActionsScope({super.key, required this.slot, required super.child});

  final RailActionsSlot slot;

  static RailActionsSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RailActionsScope>()?.slot;

  @override
  bool updateShouldNotify(RailActionsScope old) => !identical(slot, old.slot);
}

/// Déclare les boutons d'une page au menu debout, tant qu'elle est montée.
///
/// Une liste vide est une déclaration comme une autre : elle dit « cette page
/// n'a pas de boutons », et empêche ceux de la page précédente de rester.
class RailActions extends StatefulWidget {
  const RailActions({super.key, required this.actions, required this.child});

  final List<Widget> actions;
  final Widget child;

  @override
  State<RailActions> createState() => _RailActionsState();
}

class _RailActionsState extends State<RailActions> {
  RailActionsSlot? _slot;
  _RailEntry? _entry;
  ValueListenable<TickerModeData>? _visible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final slot = RailActionsScope.maybeOf(context);
    if (!identical(slot, _slot)) {
      _withdraw();
      _slot = slot;
      if (slot != null) {
        _entry = _RailEntry(widget.actions, true);
        slot._add(_entry!);
      }
    }
    final visible = TickerMode.getValuesNotifier(context);
    if (!identical(visible, _visible)) {
      _visible?.removeListener(_onVisibilityChanged);
      _visible = visible..addListener(_onVisibilityChanged);
    }
    _onVisibilityChanged();
  }

  @override
  void didUpdateWidget(RailActions old) {
    super.didUpdateWidget(old);
    final entry = _entry;
    if (entry == null) return;
    // Les boutons d'une page changent à l'usage : un filtre s'allume, le
    // « + » disparaît sur un jardin qu'on ne peut pas modifier.
    if (!_sameActions(entry.actions, widget.actions)) {
      entry.actions = widget.actions;
      _slot?._schedule();
    }
  }

  @override
  void dispose() {
    _visible?.removeListener(_onVisibilityChanged);
    _withdraw();
    super.dispose();
  }

  void _onVisibilityChanged() {
    final entry = _entry;
    final slot = _slot;
    if (entry == null || slot == null) return;
    entry.visible = _visible?.value.enabled ?? true;
    if (entry.visible) {
      slot._promote(entry);
    } else {
      slot._schedule();
    }
  }

  void _withdraw() {
    final entry = _entry;
    if (entry != null) _slot?._remove(entry);
    _entry = null;
  }

  /// Deux listes de boutons se valent quand ce sont les mêmes objets : une
  /// page qui se reconstruit sans rien changer ne doit pas redessiner la
  /// colonne.
  static bool _sameActions(List<Widget> a, List<Widget> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
