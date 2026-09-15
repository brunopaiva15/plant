package ch.vergasta.plant

import android.app.Activity
import androidx.activity.result.ActivityResultCaller
import com.google.home.FactoryRegistry
import com.google.home.Home
import com.google.home.HomeClient
import com.google.home.HomeConfig
import com.google.home.HomeDevice
import com.google.home.PermissionsResultStatus
import com.google.home.PermissionsState
import com.google.home.matter.standard.HumiditySensorDevice
import com.google.home.matter.standard.RelativeHumidityMeasurement
import com.google.home.matter.standard.TemperatureMeasurement
import com.google.home.matter.standard.TemperatureSensorDevice
import com.google.home.matter.standard.Thermostat
import com.google.home.matter.standard.ThermostatDevice
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/**
 * Les appareils de Google Home, lus par les Home APIs pour la partie Dart
 * (`lib/data/services/google_home_climate_service.dart`).
 *
 * Mêmes trois questions que pour Apple Maison côté iOS, sur un autre canal :
 * ce que la maison laisse faire, la liste des appareils qui mesurent la
 * température ou l'humidité, la mesure de l'un d'eux. Aucune commande
 * envoyée, aucun autre appareil lu.
 *
 * Cette version-ci ne se compile qu'avec le SDK des Home APIs, dont
 * l'archive est déjà un dépôt Maven : `-PgoogleHomeRepo=<dossier>`. Sans
 * lui, c'est la version muette du jeu de sources `noGoogleHome` qui prend sa
 * place. La marche à suivre est dans `docs/05-technical-architecture.md`,
 * section « Google Home ».
 *
 * Les appels au SDK sont écrits contre les signatures réelles du
 * `classes.jar` de `play-services-home` 17.1.0.
 */
object GoogleHomeChannel {
  const val NAME = "ch.vergasta.plant/google_home_climate"

  private var client: HomeClient? = null

  /** Une autorisation refusée : un refus n'est pas une question jamais posée. */
  private var refused = false

  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

  fun register(activity: Activity, messenger: BinaryMessenger) {
    // Ce que l'application lit, et rien de plus : deux grandeurs, trois types
    // d'appareil. Le registre dit au SDK ce qu'il doit savoir rendre.
    val registry =
        FactoryRegistry(
            traits = listOf(TemperatureMeasurement, RelativeHumidityMeasurement, Thermostat),
            types = listOf(TemperatureSensorDevice, HumiditySensorDevice, ThermostatDevice),
        )
    // Le premier paramètre de `HomeConfig` est un booléen, pas le contexte de
    // coroutines : tout se nomme, sinon on se trompe silencieusement.
    val home = Home.getClient(context = activity, homeConfig = HomeConfig(coroutineContext = Dispatchers.IO, factoryRegistry = registry))
    // La fenêtre d'autorisation rend sa réponse à l'activité : sans un
    // `ActivityResultCaller`, elle ne peut pas être demandée. C'est pourquoi
    // `HostActivity` est un `FlutterFragmentActivity` dans ce jeu de sources.
    (activity as? ActivityResultCaller)?.let { home.registerActivityResultCallerForPermissions(it) }
    client = home
    MethodChannel(messenger, NAME).setMethodCallHandler { call, result -> handle(call, result) }
  }

  private fun handle(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "access" -> reply(result, "unavailable") { accessName() }
      // Il n'y a pas de session à fermer de ce côté : les Home APIs Android
      // n'exposent que l'autorisation du compte, et elle se retire depuis ce
      // compte — l'écran y mène. Reste le refus à oublier, pour que la
      // question puisse se reposer.
      "disconnect" -> {
        refused = false
        result.success(null)
      }
      "sensors" -> reply(result, emptyList<Map<String, Any>>()) { sensors() }
      "read" -> {
        val id = call.argument<String>("id")
        if (id.isNullOrEmpty()) {
          result.error("bad_args", "sensor id missing", null)
        } else {
          reply(result, null) { read(id) }
        }
      }
      else -> result.notImplemented()
    }
  }

  /**
   * Répond sur le canal, depuis le fil principal. Une maison qui jette vaut
   * la réponse vide : l'écran sait déjà la montrer, et une exception ici
   * emporterait l'application.
   */
  private fun reply(result: MethodChannel.Result, fallback: Any?, body: suspend () -> Any?) {
    scope.launch {
      val value =
          try {
            body()
          } catch (e: Exception) {
            fallback
          }
      result.success(value)
    }
  }

  // Autorisation

  private suspend fun state(): PermissionsState? =
      client?.hasPermissions()?.first { it != PermissionsState.PERMISSIONS_STATE_UNINITIALIZED }

  private suspend fun accessName(): String =
      when (state()) {
        PermissionsState.GRANTED -> "authorized"
        PermissionsState.NOT_GRANTED -> if (refused) "denied" else "notDetermined"
        else -> "unavailable"
      }

  /**
   * L'autorisation, demandée une fois si elle n'a pas encore été donnée.
   * Seule la liste des appareils la demande : lire une mesure ne doit pas
   * ouvrir une fenêtre sous les yeux de qui consulte une fiche de plante.
   */
  private suspend fun granted(prompting: Boolean): Boolean {
    val home = client ?: return false
    if (state() == PermissionsState.GRANTED) return true
    if (!prompting) return false
    val answer = home.requestPermissions()
    if (answer.status != PermissionsResultStatus.SUCCESS) {
      refused = true
      return false
    }
    return true
  }

  // Appareils

  /**
   * Les appareils qui mesurent la température ou l'humidité de l'air, avec
   * leur pièce et leur maison. Tout se demande à plat, puis se recolle par
   * identifiant.
   */
  private suspend fun sensors(): List<Map<String, Any>> {
    val home = client ?: return emptyList()
    if (!granted(prompting = true)) return emptyList()
    val rooms = home.rooms().list().associate { it.id.id to it.name }
    val structures = home.structures().list().associate { it.id.id to it.name }
    val out = mutableListOf<Map<String, Any>>()
    for (device in home.devices().list()) {
      val (temperature, humidity) = measures(device)
      if (temperature == null && humidity == null) continue
      val item =
          mutableMapOf<String, Any>(
              "id" to device.id.id,
              "name" to device.name,
              "temperature" to (temperature != null),
              "humidity" to (humidity != null),
          )
      rooms[device.roomId?.id]?.takeIf { it.isNotEmpty() }?.let { item["room"] = it }
      structures[device.structureId?.id]?.takeIf { it.isNotEmpty() }?.let { item["home"] = it }
      out.add(item)
    }
    return out
  }

  private suspend fun device(home: HomeClient, id: String): HomeDevice? = home.devices().list().firstOrNull { it.id.id == id }

  /**
   * Ce qu'un appareil mesure de l'air d'une pièce, en centièmes d'unité comme
   * Matter les compte.
   *
   * `types()` est un flux, pas une liste : on en prend le premier jeu. Trois
   * traits portent ces grandeurs, et pas de la même façon — un thermostat n'a
   * pas de trait de mesure, sa température de pièce est `localTemperature`.
   */
  private suspend fun measures(device: HomeDevice): Pair<Int?, Int?> {
    var temperature: Int? = null
    var humidity: Int? = null
    for (type in device.types().first()) {
      for (trait in type.traits()) {
        when (trait) {
          is TemperatureMeasurement -> temperature = temperature ?: trait.measuredValue?.toInt()
          is RelativeHumidityMeasurement -> humidity = humidity ?: trait.measuredValue?.toInt()
          is Thermostat -> temperature = temperature ?: trait.localTemperature?.toInt()
          else -> {}
        }
      }
    }
    return temperature to humidity
  }

  // Mesure

  private suspend fun read(id: String): Map<String, Any> {
    val out = mutableMapOf<String, Any>("at" to System.currentTimeMillis())
    val home = client
    if (home == null || !granted(prompting = false)) {
      out["error"] = "unauthorized"
      return out
    }
    val device = device(home, id)
    if (device == null) {
      out["error"] = "unknown device"
      return out
    }
    val (temperature, humidity) = measures(device)
    // Matter compte en centièmes de degré et de pour cent.
    temperature?.let { out["temperature"] = it / 100.0 }
    humidity?.let { out["humidity"] = it / 100.0 }
    if (temperature == null && humidity == null) out["error"] = "no measurement"
    return out
  }
}
