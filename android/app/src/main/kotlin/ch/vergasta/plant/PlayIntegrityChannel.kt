package ch.vergasta.plant

import android.content.Context
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityException
import com.google.android.play.core.integrity.StandardIntegrityManager
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import com.google.android.play.core.integrity.model.StandardIntegrityErrorCode
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Play Integrity, pour le relais des clés (`lib/core/network/play_integrity.dart`).
 *
 * Le pendant Android d'App Attest : le Play Store de l'appareil rend un jeton
 * chiffré qui scelle le condensé que Dart lui donne — celui du défi du relais
 * et de l'identifiant d'installation. Seul Google sait l'ouvrir ; le relais
 * le lui fait déchiffrer (`supabase/functions/relay/integrity.ts`).
 *
 * L'API « standard » : un fournisseur se prépare une fois, ce qui prend une
 * ou deux secondes, puis chaque jeton ne coûte qu'un appel local. Un
 * fournisseur que Google déclare périmé se refait, une fois.
 */
object PlayIntegrityChannel {
  const val NAME = "ch.vergasta.plant/play_integrity"

  private var provider: StandardIntegrityTokenProvider? = null
  private var preparedFor: Long? = null

  fun register(context: Context, messenger: BinaryMessenger) {
    val manager = IntegrityManagerFactory.createStandard(context.applicationContext)
    MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
      if (call.method != "token") {
        result.notImplemented()
        return@setMethodCallHandler
      }
      // Dart envoie un `int` : il arrive en `Integer` ou en `Long` selon sa
      // taille, et un numéro de projet Google Cloud dépasse souvent le premier.
      val project = call.argument<Number>("cloudProjectNumber")?.toLong()
      val hash = call.argument<String>("requestHash")
      if (project == null || project <= 0 || hash.isNullOrEmpty()) {
        result.error("bad_args", "cloudProjectNumber et requestHash attendus", null)
        return@setMethodCallHandler
      }
      token(manager, project, hash, retry = true) { code, value ->
        if (value != null) result.success(value) else result.error(code, "Play Integrity a refusé", null)
      }
    }
  }

  private fun token(
      manager: StandardIntegrityManager,
      project: Long,
      hash: String,
      retry: Boolean,
      done: (String, String?) -> Unit,
  ) {
    withProvider(manager, project, { code -> done(code, null) }) { ready ->
      ready
          .request(StandardIntegrityTokenRequest.builder().setRequestHash(hash).build())
          .addOnSuccessListener { done("", it.token()) }
          .addOnFailureListener { e ->
            val code = codeOf(e)
            if (retry && code == StandardIntegrityErrorCode.INTEGRITY_TOKEN_PROVIDER_INVALID.toString()) {
              // Le fournisseur a vieilli : on en prépare un neuf, et on redemande.
              provider = null
              token(manager, project, hash, retry = false, done)
            } else {
              done(code, null)
            }
          }
    }
  }

  private fun withProvider(
      manager: StandardIntegrityManager,
      project: Long,
      failed: (String) -> Unit,
      ready: (StandardIntegrityTokenProvider) -> Unit,
  ) {
    val known = provider
    if (known != null && preparedFor == project) {
      ready(known)
      return
    }
    manager
        .prepareIntegrityToken(PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(project).build())
        .addOnSuccessListener {
          provider = it
          preparedFor = project
          ready(it)
        }
        .addOnFailureListener { failed(codeOf(it)) }
  }

  /** Le code de Google Play (`-3` pour le réseau…), ou `failed` s'il n'y en a pas. */
  private fun codeOf(e: Exception): String = (e as? StandardIntegrityException)?.errorCode?.toString() ?: "failed"
}
