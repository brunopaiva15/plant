package ch.vergasta.plant

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger

/**
 * Google Home sans son SDK : rien à enregistrer.
 *
 * Le SDK des Home APIs ne se prend ni sur Maven Central ni sur le dépôt
 * Google : il se télécharge depuis la console Google Home pour un projet
 * déclaré, et s'installe dans le dépôt Maven local. L'application se
 * construit sans lui — c'est même la construction par défaut. Le canal reste
 * alors absent, et Dart lit une maison vide au lieu d'attendre une réponse
 * qui ne viendrait pas.
 */
object GoogleHomeChannel {
  @Suppress("UNUSED_PARAMETER")
  fun register(activity: Activity, messenger: BinaryMessenger) {
    // Volontairement vide.
  }
}
