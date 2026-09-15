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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
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

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
    if (googleHome) {
        // Le cadre, puis les types et les traits. Les deux sont dans
        // l'archive ; leurs dépendances transitives — dont
        // `kotlinx-coroutines`, que le canal utilise — viennent de `google()`
        // et de `mavenCentral()`, déjà déclarés.
        implementation("com.google.android.gms:play-services-home:17.1.0")
        implementation("com.google.android.gms:play-services-home-types:17.1.0")
    }
}
