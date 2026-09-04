import 'package:flutter/foundation.dart';

/// Plateforme forcée (revue visuelle sur le web : `?ios`). `null` = réelle.
/// Injectée dans `ThemeData.platform`, donc suivie par tous les helpers
/// adaptatifs (`isCupertino`, transitions, physiques de défilement).
TargetPlatform? platformOverride;
