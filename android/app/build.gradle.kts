import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Home : le SDK des Home APIs ne se prend ni sur Maven Central ni sur
// le dépôt Google. Il se télécharge depuis la console Google Home pour un
// projet déclaré, sous la forme d'une archive qui est déjà un dépôt Maven
// (`com/google/android/gms/play-services-home/...`). Il suffit donc de
// dézipper et de donner le chemin :
//
//     flutter build apk -PgoogleHomeRepo=C:/sdk/home.android.sdk_1_10_1
//
// Sans ce chemin — la construction par défaut — c'est la version muette du
// canal qui se compile, et l'application se construit comme avant. Voir
// `docs/05-technical-architecture.md`, section « Google Home ».
// La clé d'envoi de Google Play : `android/key.properties`, jamais commité
// (voir `android/.gitignore`), qui nomme le fichier `.jks` et ses mots de
// passe. Sans lui, la construction release est signée avec la clé de debug —
// `flutter run --release` marche, et Google Play refuse le paquet, ce qui
// est voulu. La marche à suivre est dans `docs/20-android.md`.
val keystore = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

val googleHomeRepo = project.findProperty("googleHomeRepo") as String?
val googleHome = !googleHomeRepo.isNullOrBlank()

android {
    namespace = "ch.vergasta.plant"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Le même identifiant que le paquet iOS (`AppConfig.bundleId`) : il
        // ne change plus une fois publié sur Google Play.
        applicationId = "ch.vergasta.plant"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Un jeu de sources ou l'autre, jamais les deux : `GoogleHomeChannel` et
    // `HostActivity` existent en double, une version avec le SDK, une sans.
    sourceSets["main"].kotlin.srcDir(if (googleHome) "src/googleHome/kotlin" else "src/noGoogleHome/kotlin")

    signingConfigs {
        if (!keystore.isEmpty) {
            create("release") {
                keyAlias = keystore.getProperty("keyAlias")
                keyPassword = keystore.getProperty("keyPassword")
                storeFile = rootProject.file(keystore.getProperty("storeFile"))
                storePassword = keystore.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Play Integrity : le relais des clés s'en sert pour reconnaître le vrai
    // Auxine sur un vrai Android, comme App Attest sur iPhone. Voir
    // `PlayIntegrityChannel.kt` et `docs/19-relais-des-cles.md`.
    implementation("com.google.android.play:integrity:1.6.0")
    // Se connecter avec Google : la feuille du système (Credential Manager),
    // le pendant de Sign in with Apple. Voir `GoogleSignInChannel.kt`.
    implementation("androidx.credentials:credentials:1.6.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.6.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.2.1")
    if (googleHome) {
        // Le cadre, puis les types et les traits. Les deux sont dans
        // l'archive ; leurs dépendances transitives — dont
        // `kotlinx-coroutines`, que le canal utilise — viennent de `google()`
        // et de `mavenCentral()`, déjà déclarés.
        implementation("com.google.android.gms:play-services-home:17.1.0")
        implementation("com.google.android.gms:play-services-home-types:17.1.0")
    }
}
