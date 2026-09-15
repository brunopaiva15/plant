package ch.vergasta.plant

import io.flutter.embedding.engine.FlutterEngine

/**
 * L'activité de l'application. Sa classe de base change avec le SDK des Home
 * APIs (`HostActivity`, une par variante de construction) ; ce qu'elle
 * branche sur le moteur Flutter, lui, ne change pas.
 */
class MainActivity : HostActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // Les appareils de Google Home, sans plugin : un canal, trois méthodes.
    // Muet tant que le SDK des Home APIs n'est pas compilé — voir
    // `android/app/build.gradle.kts`.
    GoogleHomeChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
  }
}
