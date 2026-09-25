import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/l10n/l10n.dart';
import '../design_system/design_system.dart';
import 'launch_splash.dart';
import 'providers.dart';
import 'router.dart';

class FloraApp extends ConsumerWidget {
  const FloraApp({super.key, this.splash = false});

  /// Joue l'animation d'ouverture ([LaunchSplash]). Seul `main` la demande :
  /// les tests construisent l'application sans elle.
  final bool splash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: buildFloraTheme(Brightness.light),
      darkTheme: buildFloraTheme(Brightness.dark),
      // « Augmenter le contraste » (Réglages > Accessibilité > Écran) : le
      // système bascule sur ces deux-là. Mêmes teintes, plus de séparation.
      highContrastTheme: buildFloraTheme(Brightness.light, highContrast: true),
      highContrastDarkTheme: buildFloraTheme(Brightness.dark, highContrast: true),
      themeMode: prefs.themeMode,
      locale: prefs.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // « Réduire les animations » : réglage app, sinon réglage système.
        final reduce = prefs.reduceMotion ?? media.disableAnimations;
        // Material transparent à la racine : fournit le DefaultTextStyle aux
        // pages Cupertino (sans lui, iOS souligne les textes en jaune).
        final app = Material(
          type: MaterialType.transparency,
          child: ToastHost(child: child ?? const SizedBox.shrink()),
        );
        return MediaQuery(
          data: media.copyWith(disableAnimations: reduce),
          child: splash ? LaunchSplash(child: app) : app,
        );
      },
    );
  }
}
