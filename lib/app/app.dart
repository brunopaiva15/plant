import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/l10n/l10n.dart';
import '../design_system/design_system.dart';
import 'providers.dart';
import 'router.dart';

class FloraApp extends ConsumerWidget {
  const FloraApp({super.key});

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
        return MediaQuery(
          data: media.copyWith(disableAnimations: reduce),
          child: Material(
            type: MaterialType.transparency,
            child: ToastHost(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
