import 'dart:math' as math;

import 'package:flora/design_system/design_system.dart';
import 'package:flora/design_system/tokens/colors.dart';
import 'package:flora/features/onboarding/presentation/onboarding_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le contrat de contraste de la palette, tenu par le test plutôt que par la
/// mémoire. Une teinte qu'on retouche « juste un peu » finit toujours par
/// passer sous la barre ; ici elle ne passe pas.
///
/// Les seuils sont ceux des HIG et du WCAG AA : 4.5:1 pour du texte, 3:1 pour
/// une icône ou un contour qui porte du sens. Les palettes « contraste élevé »
/// visent AAA (7:1).

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void _expectAtLeast(Color fg, Color bg, double min, String what) {
  final r = _ratio(fg, bg);
  expect(r, greaterThanOrEqualTo(min), reason: '$what : ${r.toStringAsFixed(2)}:1, il en faut $min:1');
}

void main() {
  // (palette, seuil texte, seuil icône, nom)
  final palettes = <(FloraColors, double, double, String)>[
    (FloraColors.light, 4.5, 3.0, 'clair'),
    (FloraColors.dark, 4.5, 3.0, 'sombre'),
    (FloraColors.lightHighContrast, 7.0, 4.5, 'clair renforcé'),
    (FloraColors.darkHighContrast, 7.0, 4.5, 'sombre renforcé'),
  ];

  for (final (c, text, icon, name) in palettes) {
    group('palette $name', () {
      test('les trois encres se lisent sur les trois fonds', () {
        for (final (bg, bgName) in [(c.canvas, 'canvas'), (c.surface, 'surface'), (c.surfaceMuted, 'surfaceMuted')]) {
          _expectAtLeast(c.ink, bg, text, 'ink sur $bgName');
          _expectAtLeast(c.inkSecondary, bg, text, 'inkSecondary sur $bgName');
          // L'encre tertiaire porte les libellés des champs de saisie : c'est
          // du texte, pas une nuance décorative.
          _expectAtLeast(c.inkTertiary, bg, text, 'inkTertiary sur $bgName');
        }
      });

      test('les accents qui portent du texte se lisent sur leur pastel', () {
        for (final (fg, soft, n) in [(c.sage, c.sageSoft, 'sage'), (c.terracotta, c.terracottaSoft, 'terracotta'), (c.water, c.waterSoft, 'water')]) {
          _expectAtLeast(fg, c.canvas, text, '$n sur canvas');
          _expectAtLeast(fg, c.surface, text, '$n sur surface');
          _expectAtLeast(fg, soft, text, '$n sur son pastel');
        }
        _expectAtLeast(c.danger, c.canvas, text, 'danger sur canvas');
        _expectAtLeast(c.danger, c.surface, text, 'danger sur surface');
      });

      test('les accents qui ne servent que d\'icône restent distinguables', () {
        for (final (fg, soft, n) in [(c.sun, c.sunSoft, 'sun'), (c.rose, c.roseSoft, 'rose')]) {
          _expectAtLeast(fg, c.canvas, icon, '$n sur canvas');
          _expectAtLeast(fg, c.surface, icon, '$n sur surface');
          _expectAtLeast(fg, soft, icon, '$n sur son pastel');
        }
      });

      test('la carte du modèle tient sur le pastel', () {
        // Une carte de couleur : ce qu'on y écrit ne repose plus sur les
        // fonds neutres du contrat, d'où la pleine encre. Le libellé des
        // chiffres est en `sage`, déjà tenu par le test du pastel ci-dessus.
        // La marque, elle, ne suit plus la palette : voir le groupe qui suit.
        _expectAtLeast(c.ink, c.sageSoft, text, 'ink sur sageSoft');
      });

      test('onAccent se lit sur tous les accents employés comme fond', () {
        // C'est le bouton « Arroser », le héros du matin, le bouton destructif.
        for (final (bg, n) in [(c.sage, 'sage'), (c.terracotta, 'terracotta'), (c.water, 'water'), (c.sun, 'sun'), (c.rose, 'rose'), (c.danger, 'danger')]) {
          _expectAtLeast(c.onAccent, bg, 4.5, 'onAccent sur $n');
        }
      });
    });
  }

  group("la marque d'Iris ne suit pas la palette", () {
    // Un logo garde ses couleurs : c'est ce qui en fait un logo. La marque est
    // donc hors du contrat des palettes, et doit tenir seule sur tout ce qu'on
    // lui met dessous. Les quatre fonds ci-dessous sont les mêmes dans les
    // quatre palettes — « augmenter le contraste » ne touche ni au canvas ni
    // au pastel —, un seul jeu de mesures suffit donc.
    //
    // Le seuil reste 3:1, celui d'un dessin, y compris pour les palettes
    // renforcées : la marque est décorative (`ExcludeSemantics`), le nom du
    // modèle est écrit en toutes lettres à côté d'elle, et rien de ce qu'elle
    // porte n'a besoin d'être lu.
    const surfaces = <(Color, String)>[
      (Color(0xFFF6EFE4), 'le canvas clair'),
      (Color(0xFF221A15), 'le canvas sombre'),
      (Color(0xFFE4EFE6), 'le pastel des réglages, clair'),
      (Color(0xFF2C3D31), 'le pastel des réglages, sombre'),
    ];

    test('la feuille se détache des deux thèmes, sur les mêmes pixels', () {
      for (final (bg, n) in surfaces) {
        _expectAtLeast(IrisMark.blade, bg, 3.0, 'la feuille sur $n');
      }
    });

    test('l\'iris et le cœur tiennent sur la feuille', () {
      _expectAtLeast(IrisMark.iris, IrisMark.blade, 3.0, 'l\'iris sur la feuille');
      _expectAtLeast(IrisMark.heart, IrisMark.iris, 3.0, 'le cœur sur l\'iris');
    });

    test('le halo de l\'onboarding, lui, s\'efface', () {
      // Le seul fond qu'aucune couleur figée ne pouvait tenir : le halo est de
      // la couleur de l'écran, la feuille est verte, et en sombre les deux se
      // rejoignent. La scène le retire sur cette place, et le fond recule.
      expect(OnboardingStage.haloAt(OnboardingStage.mark.toDouble()), 0);
      expect(OnboardingStage.ambienceAt(OnboardingStage.mark.toDouble()), lessThan(0.5));
    });
  });

  group('le contraste élevé renforce vraiment', () {
    test('les séparateurs deviennent visibles', () {
      // C'est la première chose qu'attend quelqu'un qui active ce réglage.
      _expectAtLeast(FloraColors.lightHighContrast.line, FloraColors.lightHighContrast.canvas, 3.0, 'line clair renforcé');
      _expectAtLeast(FloraColors.darkHighContrast.line, FloraColors.darkHighContrast.canvas, 3.0, 'line sombre renforcé');
    });

    test('aucune encre ne s\'affaiblit par rapport à la palette normale', () {
      for (final (normal, high) in [(FloraColors.light, FloraColors.lightHighContrast), (FloraColors.dark, FloraColors.darkHighContrast)]) {
        expect(_ratio(high.ink, high.canvas), greaterThanOrEqualTo(_ratio(normal.ink, normal.canvas)));
        expect(_ratio(high.inkSecondary, high.canvas), greaterThanOrEqualTo(_ratio(normal.inkSecondary, normal.canvas)));
        expect(_ratio(high.line, high.canvas), greaterThanOrEqualTo(_ratio(normal.line, normal.canvas)));
      }
    });
  });
}
