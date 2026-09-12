import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../domain/auth/auth_repository.dart';

/// `true` quand l'app peut proposer une connexion : un backend configuré, et
/// une plateforme où Sign in with Apple existe. Pas de connexion par e-mail
/// sur Auxine, et Google n'est pas livré : sur Android, le compte reste local,
/// exactement comme sans backend — et aucun écran ne promet une connexion
/// qui n'existe pas.
bool signInAvailable(AuthRepository auth) =>
    auth.supportsRemote && (defaultTargetPlatform == TargetPlatform.iOS || AppConfig.googleSignInEnabled);
