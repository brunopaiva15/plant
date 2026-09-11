import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/services/preferences_service.dart';
import '../../../design_system/design_system.dart';

/// Ce que l'application annonce quand elle vient d'être mise à jour, et la
/// règle qui décide de l'annoncer ou non.
///
/// Une nouveauté est du texte, trois points forts et une teinte : aucune
/// image à livrer, rien à charger, et la fenêtre se construit à partir de la
/// palette du moment. Écrire une nouvelle version, c'est ajouter une entrée
/// à [releaseNotes] et ses clés aux quatre `.arb` — rien d'autre.

/// Une teinte de la palette, choisie par une nouveauté pour son héros et par
/// chacun de ses points forts pour sa pastille.
///
/// Les cinq y sont, y compris l'ocre et le rose : ici l'accent ne porte
/// jamais de texte, seulement une icône, et le contrat de contraste ne leur
/// demande que 3:1 — ce qu'ils tiennent sur leur pastel comme sur la crème
/// (`colors_contrast_test.dart`). Les titres et les corps de texte restent à
/// l'encre.
enum ReleaseAccent { sage, terracotta, water, sun, rose }

extension ReleaseAccentColors on ReleaseAccent {
  /// La couleur de l'icône.
  Color color(FloraColors c) => switch (this) {
        ReleaseAccent.sage => c.sage,
        ReleaseAccent.terracotta => c.terracotta,
        ReleaseAccent.water => c.water,
        ReleaseAccent.sun => c.sun,
        ReleaseAccent.rose => c.rose,
      };

  /// Le pastel qui lui sert de fond.
  Color soft(FloraColors c) => switch (this) {
        ReleaseAccent.sage => c.sageSoft,
        ReleaseAccent.terracotta => c.terracottaSoft,
        ReleaseAccent.water => c.waterSoft,
        ReleaseAccent.sun => c.sunSoft,
        ReleaseAccent.rose => c.roseSoft,
      };
}

/// Ce qui est posé au centre du héros.
enum ReleaseMark {
  /// La marque du modèle embarqué — pour une nouveauté d'Iris.
  iris,

  /// L'icône de la nouveauté, seule au milieu de sa médaille d'argile.
  icon,
}

/// Un point fort : une icône, un titre, deux lignes.
@immutable
class ReleaseHighlight {
  const ReleaseHighlight({
    required this.icon,
    required this.title,
    required this.body,
    this.accent = ReleaseAccent.sage,
  });

  final IconData icon;
  final String title;
  final String body;
  final ReleaseAccent accent;
}

/// Où mène le lien discret du bas, sous le bouton principal.
@immutable
class ReleaseLink {
  const ReleaseLink({required this.label, required this.route});

  final String label;

  /// Une route du [Routes] de l'app, ouverte après la fermeture de la fenêtre.
  final String route;
}

/// Une version, telle que l'utilisateur la découvre.
@immutable
class ReleaseNote {
  const ReleaseNote({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.highlights,
    this.accent = ReleaseAccent.terracotta,
    this.mark = ReleaseMark.icon,
    this.icon,
    this.link,
  });

  /// Clé de persistance de la nouveauté : c'est elle, et non le numéro de
  /// version, qui dit si l'utilisateur l'a déjà vue.
  ///
  /// Un identifiant ne se renomme pas et ne se réemploie pas : le renommer
  /// rouvre la fenêtre chez tous ceux qui l'avaient déjà fermée.
  final String id;

  /// La ligne en capitales au-dessus du titre : de quoi il s'agit.
  final String eyebrow;

  /// Le titre, souvent un nom propre — « Iris 8 » — qui ne se traduit pas.
  final String title;

  /// Le paragraphe d'introduction, sous le titre.
  final String body;

  final List<ReleaseHighlight> highlights;

  /// La teinte du héros.
  final ReleaseAccent accent;

  final ReleaseMark mark;

  /// L'icône de la médaille, quand [mark] vaut [ReleaseMark.icon].
  final IconData? icon;

  final ReleaseLink? link;
}

/// Les nouveautés livrées, de la plus ancienne à la plus récente.
///
/// L'ordre compte : c'est la dernière que l'application propose, et la plus
/// récente jamais vue qu'elle annonce au lancement.
List<ReleaseNote> releaseNotes(AppLocalizations l10n) {
  // ────────────────────────────────────────────────────────────────────────
  // EXEMPLE — à remplacer à la première vraie livraison.
  //
  // Le mécanisme est en place avant d'avoir quelque chose à annoncer : cette
  // entrée sert de gabarit et de démonstration. Ses chiffres sont inventés,
  // et c'est sans conséquence tant qu'elle reste ici : livrée dans la même
  // version que le mécanisme, elle ne s'ouvre d'elle-même chez personne
  // (voir [WhatsNew.take]) et ne se voit que par Profil → Nouveautés.
  //
  // À la vraie version d'Iris 8 : reprendre le texte des quatre `.arb`, et
  // garder l'identifiant si la fenêtre n'a jamais été livrée autrement.
  // ────────────────────────────────────────────────────────────────────────
  const speciesCount = '5000';
  return [
    ReleaseNote(
      id: 'iris-8',
      eyebrow: l10n.whatsNewModelUpdate,
      title: AppConfig.modelDisplayName('8'),
      body: l10n.whatsNewIrisIntro,
      accent: ReleaseAccent.terracotta,
      mark: ReleaseMark.iris,
      link: ReleaseLink(label: l10n.identificationSettings, route: Routes.identification),
      highlights: [
        ReleaseHighlight(
          icon: CupertinoIcons.leaf_arrow_circlepath,
          accent: ReleaseAccent.sage,
          title: l10n.whatsNewIrisSpeciesTitle(speciesCount),
          body: l10n.whatsNewIrisSpeciesBody,
        ),
        ReleaseHighlight(
          icon: CupertinoIcons.wifi_slash,
          accent: ReleaseAccent.water,
          title: l10n.whatsNewIrisOfflineTitle,
          body: l10n.whatsNewIrisOfflineBody,
        ),
        ReleaseHighlight(
          icon: CupertinoIcons.question_circle,
          accent: ReleaseAccent.sun,
          title: l10n.whatsNewIrisDoubtTitle,
          body: l10n.whatsNewIrisDoubtBody,
        ),
      ],
    ),
  ];
}

/// Décide s'il y a quelque chose à annoncer, et s'en souvient.
class WhatsNew {
  const WhatsNew(this._prefs);

  final PreferencesService _prefs;

  /// La nouveauté à ouvrir au lancement, ou `null` s'il n'y a rien à dire.
  ///
  /// À n'appeler qu'une fois par lancement : la méthode consomme ce qu'elle
  /// rend. Elle enregistre au passage la version courante et marque toutes
  /// les nouveautés connues comme vues — avant l'affichage, et non après :
  /// une application tuée pendant la lecture ne doit pas rouvrir la même
  /// fenêtre au lancement suivant.
  ///
  /// Trois règles, dans cet ordre :
  ///
  /// 1. tant que l'onboarding n'est pas fait, rien — on ne raconte pas les
  ///    nouveautés d'une application que personne n'a encore ouverte ;
  /// 2. si l'appareil n'a jamais enregistré de version, l'utilisateur
  ///    découvre tout : on note la version, on marque tout comme vu, et on
  ///    se tait. C'est le cas d'une installation neuve — et aussi celui de
  ///    la mise à jour qui amène ce mécanisme, qui reste donc silencieuse ;
  /// 3. sinon, la plus récente des nouveautés jamais présentées. Deux
  ///    versions sautées n'empilent pas deux fenêtres.
  Future<ReleaseNote?> take(List<ReleaseNote> notes) async {
    if (!_prefs.onboardingDone) return null;
    final firstRun = _prefs.lastRunVersion == null;
    final seen = _prefs.seenReleaseNotes;
    await _prefs.setLastRunVersion(AppConfig.version);
    // L'union, et non la liste du catalogue : une nouveauté retirée du
    // catalogue reste vue, et son identifiant ne peut pas resservir par
    // accident.
    await _prefs.setSeenReleaseNotes({...seen, for (final n in notes) n.id});
    if (firstRun) return null;
    for (final note in notes.reversed) {
      if (!seen.contains(note.id)) return note;
    }
    return null;
  }

  /// La dernière nouveauté livrée, qu'on puisse la relire depuis les
  /// réglages. Ne consomme rien.
  ReleaseNote? latest(List<ReleaseNote> notes) => notes.isEmpty ? null : notes.last;
}

final whatsNewProvider = Provider<WhatsNew>((ref) => WhatsNew(ref.watch(preferencesServiceProvider)));
