package ch.vergasta.plant

import android.app.Activity
import androidx.activity.result.ActivityResultCaller
import com.google.home.FactoryRegistry
import com.google.home.Home
import com.google.home.HomeClient
import com.google.home.HomeConfig
import com.google.home.HomeDevice
import com.google.home.matter.common.PermissionsResultStatus
import com.google.home.matter.common.PermissionsState
import com.google.home.matter.standard.HumiditySensorDevice
import com.google.home.matter.standard.RelativeHumidityMeasurement
import com.google.home.matter.standard.TemperatureMeasurement
import com.google.home.matter.standard.TemperatureSensorDevice
import com.google.home.matter.standard.ThermostatDevice
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
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
 * Cette version-ci ne se compile qu'avec le SDK des Home APIs dans le dépôt
 * Maven local (`-PgoogleHome=true`) ; sans lui, c'est la version muette du
 * jeu de sources `noGoogleHome` qui prend sa place. La marche à suivre —
 * projet déclaré, client OAuth, empreinte SHA-1, SDK — est dans
 * `docs/05-technical-architecture.md`, section « Google Home ».
 *
 * Les appels au SDK suivent la documentation des Home APIs ; ils n'ont pas
 * été compilés ici, faute de SDK, et se vérifient à la première
 * construction avec lui.
 */
object GoogleHomeChannel {
  const val NAME = "ch.vergasta.plant/google_home_climate"

  private var client: HomeClient? = null

  /** Une autorisation refusée : un refus n'est pas une question jamais posée. */
  private var refused = false

  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

  fun register(activity: Activity, messenger: BinaryMessenger) {
    // Ce que l'application lit, et rien de plus : deux grandeurs, trois
    // types d'appareil. Le registre dit au SDK ce qu'il doit savoir rendre.
    val registry =
        FactoryRegistry(
            types = listOf(TemperatureSensorDevice, HumiditySensorDevice, ThermostatDevice),
            traits = listOf(TemperatureMeasurement, RelativeHumidityMeasurement),
        )
    val home = Home.getClient(context = activity, homeConfig = HomeConfig(Dispatchers.IO, registry))
    // La fenêtre d'autorisation rend sa réponse à l'activité : sans un
    // `ActivityResultCaller`, elle ne peut pas être demandée.
    (activity as? ActivityResultCaller)?.let { home.registerActivityResultCallerForPermissions(it) }
    client = home
    MethodChannel(messenger, NAME).setMethodCallHandler { call, result -> handle(call, result) }
  }

  private fun handle(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "access" -> reply(result, "unavailable") { accessName() }
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

  // MARK: - Autorisation

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
      refused = answer.status == PermissionsResultStatus.ERROR || answer.status == PermissionsResultStatus.CANCELLED
      return false
    }
    return true
  }

  // MARK: - Appareils

  private suspend fun sensors(): List<Map<String, Any>> {
    val home = client ?: return emptyList()
    if (!granted(prompting = true)) return emptyList()
    val out = mutableListOf<Map<String, Any>>()
    for (structure in home.structures().list()) {
      // La pièce vient de la pièce elle-même : c'est elle qui connaît ses
      // appareils, et le nom qu'elle porte chez la personne.
      val roomNames = mutableMapOf<String, String>()
      for (room in structure.rooms().list()) {
        for (device in room.devices().list()) {
          roomNames[device.id.id] = room.name
        }
      }
      for (device in structure.devices().list()) {
        val (temperature, humidity) = measures(device)
        if (temperature == null && humidity == null) continue
        val item =
            mutableMapOf<String, Any>(
                "id" to device.id.id,
                "name" to device.name,
                "home" to structure.name,
                "temperature" to (temperature != null),
                "humidity" to (humidity != null),
            )
        roomNames[device.id.id]?.takeIf { it.isNotEmpty() }?.let { item["room"] = it }
        out.add(item)
      }
    }
    return out
  }

  private suspend fun device(home: HomeClient, id: String): HomeDevice? {
    for (structure in home.structures().list()) {
      structure.devices().list().firstOrNull { it.id.id == id }?.let {
        return it
      }
    }
    return null
  }

  /**
   * Ce qu'un appareil mesure de l'air d'une pièce : la température et
   * l'humidité relative, sur n'importe lequel de ses types — un thermostat
   * mesure la pièce où il est posé, comme un capteur.
   */
  private suspend fun measures(device: HomeDevice): Pair<Double?, Double?> {
    var temperature: Double? = null
    var humidity: Double? = null
    for (type in device.types().list()) {
      for (trait in type.traits()) {
        when (trait) {
          is TemperatureMeasurement -> temperature = temperature ?: trait.measuredValue?.toDouble()
          is RelativeHumidityMeasurement -> humidity = humidity ?: trait.measuredValue?.toDouble()
          else -> {}
        }
      }
    }
    return temperature to humidity
  }

  // MARK: - Mesure

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
    temperature?.let { out["temperature"] = celsius(it) }
    humidity?.let { out["humidity"] = percent(it) }
    if (temperature == null && humidity == null) out["error"] = "no measurement"
    return out
  }

  /**
   * Matter compte en centièmes de degré ; selon sa version, le SDK rend déjà
   * des degrés. Une pièce ne dépasse pas cent degrés : au-delà, la valeur
   * est en centièmes, et se divise par cent.
   */
  private fun celsius(raw: Double): Double = if (abs(raw) > 100) raw / 100 else raw

  /** Même règle pour l'humidité relative, comptée en centièmes de pour cent. */
  private fun percent(raw: Double): Double = if (raw > 100) raw / 100 else raw
}
