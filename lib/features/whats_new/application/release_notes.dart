import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
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
///
/// Un gros morceau a sa fiche à lui. Les ajouts courts se rassemblent sous
/// « Petites nouveautés », un lot par entrée, numérotée : voir le commentaire
/// de [releaseNotes].

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
  // « Petites nouveautés » : la fiche des ajouts courts.
  //
  // Tout ce qui arrive entre deux gros morceaux — un champ de plus, un geste
  // raccourci — n'a pas de quoi remplir une fiche à soi. Ces ajouts se
  // rassemblent donc sous la même ligne en capitales, le titre disant le
  // sujet du lot, et trois points forts au plus : c'est ce que la fenêtre
  // montre sans se tasser.
  //
  // Le lot suivant est une **entrée de plus**, jamais une retouche de
  // celle-ci : un identifiant déjà vu ne se rejoue pas, et éditer cette
  // entrée n'annoncerait rien à ceux qui l'ont fermée. Ce sera donc
  // `small-updates-2`, puis `small-updates-3`.
  //
  // `iris-8` est dépensé : l'exemple livré avec le mécanisme le portait, et
  // tout appareil ayant lancé cette version-là l'a dans ses nouveautés vues.
  // La vraie livraison d'Iris 8 en prendra un autre — `iris-8-modele` fera
  // l'affaire — et retrouvera ses textes dans les quatre `.arb`, restés au
  // chaud sous `whatsNewIris…`.
  // ────────────────────────────────────────────────────────────────────────
  return [
    ReleaseNote(
      id: 'small-updates-1',
      eyebrow: l10n.whatsNewSmallUpdates,
      title: l10n.diagnosisTitle,
      body: l10n.whatsNewDiagnosisIntro,
      accent: ReleaseAccent.sage,
      icon: CupertinoIcons.bandage,
      // Pas de lien du bas : il mènerait au réglage « Diagnostic », déjà le
      // titre de la fiche, et le geste se trouve sur la fiche d'une plante,
      // là où l'on va quand elle ne va pas bien.
      highlights: [
        ReleaseHighlight(
          icon: CupertinoIcons.square_list,
          accent: ReleaseAccent.water,
          title: l10n.whatsNewDiagnosisChecksTitle,
          body: l10n.whatsNewDiagnosisChecksBody,
        ),
        ReleaseHighlight(
          icon: CupertinoIcons.sparkles,
          accent: ReleaseAccent.sun,
          title: l10n.whatsNewDiagnosisWeighTitle,
          body: l10n.whatsNewDiagnosisWeighBody,
        ),
        ReleaseHighlight(
          icon: CupertinoIcons.book,
          accent: ReleaseAccent.sage,
          title: l10n.whatsNewDiagnosisKeptTitle,
          body: l10n.whatsNewDiagnosisKeptBody,
        ),
      ],
    ),
  ];
}

/// Décide s'il y a quelque chose à annoncer, et s'en souvient.
class WhatsNew {
  const WhatsNew(this._prefs, this._version);

  final PreferencesService _prefs;

  /// La version qui tourne, telle que [AppVersion] la lit sur le binaire.
  final String _version;

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
    await _prefs.setLastRunVersion(_version);
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

final whatsNewProvider = Provider<WhatsNew>((ref) => WhatsNew(ref.watch(preferencesServiceProvider), ref.watch(appVersionProvider).name));
