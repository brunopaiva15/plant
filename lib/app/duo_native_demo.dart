import '../core/l10n/l10n.dart';
import '../core/native_chrome.dart';

/// **Prototype.** Le jeu de boutons qu'on donne à UIKit pour voir ce qu'il en
/// fait sur l'iPhone Duo.
///
/// Ce ne sont pas les vrais boutons de l'application, et c'est voulu : les
/// pages publient des widgets Flutter, qu'UIKit ne sait pas dessiner. On lui
/// donne donc un jeu représentatif — un retour, plusieurs actions, une action
/// de bas de bande — et on regarde.
///
/// Sept actions, ce n'est pas un hasard : Apple dit qu'au-delà de ce que la
/// bande peut tenir, les éléments se replient dans un menu de débordement.
/// C'est l'une des deux choses que la colonne Flutter ne sait pas faire, et
/// la seule façon de la voir est d'en envoyer trop.
abstract final class DuoNativeDemo {
  static void publish(AppLocalizations l10n, int onglet) {
    final titres = [l10n.tabToday, l10n.tabPlants, l10n.tabGarden, l10n.tabProfile];
    NativeChrome.publish(
      title: titres[onglet.clamp(0, titres.length - 1)],
      items: const [
        NativeChromeItem(
          id: 'retour',
          symbol: 'chevron.backward',
          title: 'Retour',
          placement: NativeChromePlacement.primary,
        ),
        NativeChromeItem(id: 'ajouter', symbol: 'plus', title: 'Ajouter'),
        NativeChromeItem(id: 'tableau', symbol: 'chart.bar', title: 'Tableau de bord'),
        NativeChromeItem(id: 'chercher', symbol: 'magnifyingglass', title: 'Chercher'),
        NativeChromeItem(id: 'trier', symbol: 'arrow.up.arrow.down', title: 'Trier'),
        NativeChromeItem(id: 'filtrer', symbol: 'line.3.horizontal.decrease', title: 'Filtrer'),
        NativeChromeItem(id: 'partager', symbol: 'square.and.arrow.up', title: 'Partager'),
        NativeChromeItem(
          id: 'reglages',
          symbol: 'gearshape',
          title: 'Réglages',
          placement: NativeChromePlacement.bottom,
        ),
      ],
    );
  }
}
