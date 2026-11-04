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
    // KLD-120: keep the screen on while a network game runs
    // (lib/app/screen_awake.dart); a locked phone drops the connection.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KlunkiScreenAwake") {
      let channel = FlutterMethodChannel(name: "klunki/screen", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "keepOn", let on = call.arguments as? Bool else {
          result(FlutterMethodNotImplemented)
          return
        }
        DispatchQueue.main.async {
          UIApplication.shared.isIdleTimerDisabled = on
          result(nil)
        }
      }
    }
  }
}
