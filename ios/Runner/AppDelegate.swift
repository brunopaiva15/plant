import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Les capteurs d'Apple Maison, sans plugin : un canal, trois méthodes.
    HomeClimateChannel.register(with: engineBridge.applicationRegistrar.messenger())
    // Ceux de Google Home, sur le même modèle. Muet tant que le SDK des
    // Home APIs n'est pas dans le projet : le canal ne s'enregistre pas.
    GoogleHomeChannel.register(with: engineBridge.applicationRegistrar.messenger())
    // Les motifs Core Haptics : la goutte, le roulement, le coup sourd.
    HapticsChannel.register(with: engineBridge.applicationRegistrar.messenger())
    // Les soins du jour, écrits pour le widget de l'écran d'accueil.
    TodayWidgetChannel.register(with: engineBridge.applicationRegistrar.messenger())
    // Les raccourcis de l'icône : posés par Dart, rendus par la scène.
    QuickActionsChannel.register(with: engineBridge.pluginRegistry)
  }
}
