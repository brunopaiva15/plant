package ch.vergasta.plant

import android.app.Activity
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.ClearCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

/**
 * Se connecter avec Google, pour `SupabaseAuthRepository.signInWithGoogle`.
 *
 * Le pendant de Sign in with Apple sur iPhone : la feuille du système
 * (Credential Manager), pas de navigateur. Google rend un jeton d'identité
 * signé, que Dart échange contre une session Supabase (`signInWithIdToken`),
 * avec un nonce pour lier les deux — exactement comme pour Apple.
 *
 * Sans plugin, comme Google Home : un canal, deux méthodes, et rien qui
 * touche à la construction iOS.
 */
object GoogleSignInChannel {
  const val NAME = "ch.vergasta.plant/google_sign_in"

  private val main = Executor { Handler(Looper.getMainLooper()).post(it) }

  fun register(activity: Activity, messenger: BinaryMessenger) {
    val manager = CredentialManager.create(activity)
    MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
      when (call.method) {
        "signIn" -> {
          val clientId = call.argument<String>("serverClientId")
          val nonce = call.argument<String>("nonce")
          if (clientId.isNullOrEmpty() || nonce.isNullOrEmpty()) {
            result.error("bad_args", "serverClientId et nonce attendus", null)
            return@setMethodCallHandler
          }
          signIn(activity, manager, clientId, nonce, result)
        }
        // La feuille proposera de nouveau le choix du compte : sans cela,
        // se reconnecter reprendrait d'office celui qu'on vient de quitter.
        "signOut" ->
            manager.clearCredentialStateAsync(
                ClearCredentialStateRequest(),
                CancellationSignal(),
                main,
                object : CredentialManagerCallback<Void?, ClearCredentialException> {
                  override fun onResult(response: Void?) = result.success(null)

                  override fun onError(e: ClearCredentialException) = result.success(null)
                },
            )
        else -> result.notImplemented()
      }
    }
  }

  private fun signIn(
      activity: Activity,
      manager: CredentialManager,
      clientId: String,
      nonce: String,
      result: MethodChannel.Result,
  ) {
    // Le bouton « Se connecter avec Google » : la feuille liste les comptes
    // de l'appareil et permet d'en ajouter un, plutôt que de ne proposer que
    // ceux qui ont déjà autorisé l'application.
    val option = GetSignInWithGoogleOption.Builder(clientId).setNonce(nonce).build()
    val request = GetCredentialRequest.Builder().addCredentialOption(option).build()
    manager.getCredentialAsync(
        activity,
        request,
        CancellationSignal(),
        main,
        object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
          override fun onResult(response: GetCredentialResponse) {
            val credential = response.credential
            if (credential !is CustomCredential ||
                credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
              result.error("unexpected", "identifiant inattendu", null)
              return
            }
            val google = GoogleIdTokenCredential.createFrom(credential.data)
            result.success(mapOf("idToken" to google.idToken, "givenName" to google.givenName))
          }

          override fun onError(e: GetCredentialException) {
            val code =
                when (e) {
                  // Refermer la feuille n'est pas une erreur, comme pour Apple.
                  is GetCredentialCancellationException -> "cancelled"
                  is NoCredentialException -> "no_account"
                  else -> "failed"
                }
            result.error(code, e.message, null)
          }
        },
    )
  }
}
