import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Grille ou liste pour la section « À venir » de l'écran du jour.
///
/// Le choix se fait d'un seul geste, dans l'en-tête de la section, et se
/// retrouve au lancement suivant : c'est une façon de regarder ses soins, pas
/// un réglage à reprendre chaque matin.
class UpcomingViewController extends Notifier<bool> {
  @override
  bool build() => ref.read(preferencesServiceProvider).upcomingGridView;

  void set(bool grid) {
    if (grid == state) return;
    ref.read(preferencesServiceProvider).setUpcomingGridView(grid);
    state = grid;
  }

  void toggle() => set(!state);
}

final upcomingGridProvider = NotifierProvider<UpcomingViewController, bool>(UpcomingViewController.new);
