import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';
import '../data/services/quick_actions_service.dart';
import '../features/plants/presentation/create_plant_flow.dart';
import 'router.dart';

/// Les trois raccourcis de l'icône, et ce que chacun ouvre.
abstract final class QuickActions {
  static const String add = 'add';
  static const String scan = 'scan';
  static const String finder = 'finder';

  /// Les raccourcis dans la langue courante. L'ordre est celui de l'écran
  /// Plantes : ajouter, scanner, trouver.
  static List<QuickAction> items(AppLocalizations l10n) => [
        QuickAction(type: add, title: l10n.addPlant, icon: 'plus'),
        QuickAction(type: scan, title: l10n.quickActionScan, icon: 'qrcode.viewfinder'),
        QuickAction(type: finder, title: l10n.finderTitle, icon: 'lightbulb'),
      ];
}

final quickActionsServiceProvider = Provider<QuickActionsService>((ref) => QuickActionsService());

/// Le raccourci choisi et pas encore exécuté.
///
/// Il arrive de deux façons : par le natif pendant que l'application tourne,
/// ou au lancement, quand c'est lui qui l'a ouverte. Dans les deux cas il
/// attend ici que la coquille soit à l'écran — après l'onboarding, s'il y en
/// a un — et [QuickActionsHost] le consomme.
class PendingQuickAction extends Notifier<String?> {
  @override
  String? build() {
    final service = ref.watch(quickActionsServiceProvider);
    service.onAction = (type) => state = type;
    service.launchAction().then((type) {
      if (type != null) state = type;
    });
    return null;
  }

  String? take() {
    final type = state;
    state = null;
    return type;
  }
}

final pendingQuickActionProvider = NotifierProvider<PendingQuickAction, String?>(PendingQuickAction.new);

/// Pose les raccourcis de l'icône dans la langue de l'interface, et exécute
/// celui qui a été choisi. À placer autour de la coquille : c'est là que
/// l'application atterrit, et les raccourcis n'appartiennent à aucun onglet.
class QuickActionsHost extends ConsumerStatefulWidget {
  const QuickActionsHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<QuickActionsHost> createState() => _QuickActionsHostState();
}

class _QuickActionsHostState extends ConsumerState<QuickActionsHost> {
  Locale? _published;

  @override
  void initState() {
    super.initState();
    // Après la première image : la coquille a un fond sur lequel ouvrir une
    // sheet, et un routeur à qui pousser une page.
    WidgetsBinding.instance.addPostFrameCallback((_) => _perform());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (locale == _published) return;
    _published = locale;
    ref.read(quickActionsServiceProvider).setItems(QuickActions.items(context.l10n));
  }

  void _perform() {
    if (!mounted) return;
    final type = ref.read(pendingQuickActionProvider.notifier).take();
    if (type == null) return;
    switch (type) {
      case QuickActions.add:
        startCreatePlantFlow(context, ref);
      case QuickActions.scan:
        context.push(Routes.scan);
      case QuickActions.finder:
        context.push(Routes.finder);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingQuickActionProvider, (_, type) {
      if (type != null) _perform();
    });
    return widget.child;
  }
}
