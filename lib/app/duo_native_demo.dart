import 'package:flutter/foundation.dart';

import '../core/l10n/l10n.dart';
import '../core/native_chrome.dart';

/// **Prototype.** Le jeu de boutons qu'on donne à UIKit pour voir ce qu'il en
/// fait sur l'iPhone Duo, et deux interrupteurs pour trancher ce que la
/// première capture a laissé ouvert.
///
/// Ce que la capture du 20 septembre 2026 a montré, écran extérieur :
///
/// - iOS **range bien** les boutons debout dans la bande. Le retour tout en
///   haut dans sa propre capsule, les actions groupées dans une seconde, et
///   l'élément de bas de barre isolé en bas. C'est l'ordre annoncé ;
/// - il garde en même temps une **bande horizontale en haut** pour le titre,
///   et elle coûte 82 points de marge sûre. « Aujourd'hui » s'y affiche
///   au-dessus du « Bonsoir » d'Auxine : deux titres pour une page ;
/// - la colonne native et la colonne en argile occupent **la même bande**.
///
/// D'où les deux interrupteurs, posés en bas de la bande native. Ils évitent
/// une reconstruction par question :
///
/// - « Titre natif » : sans titre, la bande horizontale du haut disparaît-elle
///   — et les 82 points avec elle — ou reste-t-elle vide ?
/// - « Colonne Flutter » : la bande native seule, sans l'argile derrière, pour
///   la juger sur pièce.
///
/// Six actions de remplissage, parce qu'il faut en envoyer trop pour voir si
/// iOS les replie dans un menu de débordement. Sur l'écran extérieur, les huit
/// tenaient sans déborder.
abstract final class DuoNativeDemo {
  /// Publier un titre, ou non.
  static final ValueNotifier<bool> titreNatif = ValueNotifier<bool>(true);

  /// Laisser la colonne en argile derrière, ou non.
  static final ValueNotifier<bool> colonneFlutter = ValueNotifier<bool>(true);

  static Listenable get interrupteurs => Listenable.merge([titreNatif, colonneFlutter]);

  static void attach() {
    NativeChrome.onItem = (id) {
      switch (id) {
        case 'titre':
          titreNatif.value = !titreNatif.value;
        case 'colonne':
          colonneFlutter.value = !colonneFlutter.value;
      }
    };
  }

  static void publish(AppLocalizations l10n, int onglet) {
    final titres = [l10n.tabToday, l10n.tabPlants, l10n.tabGarden, l10n.tabProfile];
    NativeChrome.publish(
      title: titreNatif.value ? titres[onglet.clamp(0, titres.length - 1)] : '',
      items: [
        const NativeChromeItem(
          id: 'retour',
          symbol: 'chevron.backward',
          title: 'Retour',
          placement: NativeChromePlacement.primary,
        ),
        const NativeChromeItem(id: 'ajouter', symbol: 'plus', title: 'Ajouter'),
        const NativeChromeItem(id: 'tableau', symbol: 'chart.bar', title: 'Tableau de bord'),
        const NativeChromeItem(id: 'chercher', symbol: 'magnifyingglass', title: 'Chercher'),
        const NativeChromeItem(id: 'trier', symbol: 'arrow.up.arrow.down', title: 'Trier'),
        const NativeChromeItem(id: 'filtrer', symbol: 'line.3.horizontal.decrease', title: 'Filtrer'),
        const NativeChromeItem(id: 'partager', symbol: 'square.and.arrow.up', title: 'Partager'),
        // Les deux interrupteurs, en bas de la bande.
        NativeChromeItem(
          id: 'titre',
          symbol: titreNatif.value ? 'textformat' : 'textformat.slash',
          title: 'Titre natif',
          placement: NativeChromePlacement.bottom,
        ),
        NativeChromeItem(
          id: 'colonne',
          symbol: colonneFlutter.value ? 'sidebar.right' : 'sidebar.squares.right',
          title: 'Colonne Flutter',
          placement: NativeChromePlacement.bottom,
        ),
      ],
    );
  }
}
