package ch.vergasta.plant

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * La fiche de l'application dans les Paramètres, pour `lib/core/system_settings.dart`.
 *
 * iOS l'ouvre par une URL (`app-settings:`) ; Android demande une intention,
 * que `url_launcher` ne sait pas construire. Une permission refusée deux fois
 * ne se redemande plus sur Android non plus : sans ce raccourci, l'écran des
 * rappels et le viseur restaient des impasses.
 */
object SystemSettingsChannel {
  const val NAME = "ch.vergasta.plant/system_settings"

  fun register(activity: Activity, messenger: BinaryMessenger) {
    MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
      if (call.method != "open") {
        result.notImplemented()
        return@setMethodCallHandler
      }
      val intent =
          Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", activity.packageName, null))
      try {
        activity.startActivity(intent)
        result.success(true)
      } catch (e: ActivityNotFoundException) {
        result.success(false)
      }
    }
  }
}
