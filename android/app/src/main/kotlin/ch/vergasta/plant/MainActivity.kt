package ch.vergasta.plant

import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine

/**
 * L'activité de l'application. Sa classe de base change avec le SDK des Home
 * APIs (`HostActivity`, une par variante de construction) ; ce qu'elle
 * branche sur le moteur Flutter, lui, ne change pas.
 */
class MainActivity : HostActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    holdOrientation(resources.configuration)
  }

  override fun onConfigurationChanged(newConfig: Configuration) {
    super.onConfigurationChanged(newConfig)
    // Un pliable qu'on ouvre ou qu'on ferme ne relance pas l'activité
    // (`configChanges` du manifeste) : la règle se relit ici.
    holdOrientation(newConfig)
  }

  /**
   * La règle de l'iPhone et de l'iPad : portrait sur téléphone, libre sur
   * tablette et sur un pliable ouvert. Le manifeste ne sait pas le dire selon
   * la taille, et un verrou « portrait » partout serait de toute façon ignoré
   * sur grand écran depuis Android 16 (cible SDK 36). Même limite que
   * `compactWindowWidth` côté Dart : 600 dp de côté le plus court.
   */
  private fun holdOrientation(config: Configuration) {
    val wanted =
        if (config.smallestScreenWidthDp >= 600) ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        else ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    if (requestedOrientation != wanted) requestedOrientation = wanted
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // Les appareils de Google Home, sans plugin : un canal, trois méthodes.
    // Muet tant que le SDK des Home APIs n'est pas compilé — voir
    // `android/app/build.gradle.kts`.
    GoogleHomeChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
    // Le relais des clés : Play Integrity, le pendant d'App Attest.
    PlayIntegrityChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
    // Se connecter avec Google, le pendant de Sign in with Apple.
    GoogleSignInChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
    // La fiche de l'application dans les Paramètres, après un refus.
    SystemSettingsChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
  }
}
