import CoreMotion
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// KLD-121 follow-up: the accelerometer for "Schütteln zum Würfeln".
  private let accelerometer = KlunkiAccelerometer()

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
    // KLD-121 follow-up: accelerometer samples for shake to roll
    // (lib/platform/shake.dart); the sensor runs only while Dart listens.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KlunkiAccelerometer") {
      let events = FlutterEventChannel(name: "klunki/accelerometer", binaryMessenger: registrar.messenger())
      events.setStreamHandler(accelerometer)
    }
  }
}

/// Sends `[x, y, z, ms]` (acceleration incl. gravity in g, a timestamp in
/// milliseconds) about 50 times a second while listened to. CoreMotion's raw
/// accelerometer needs no permission.
final class KlunkiAccelerometer: NSObject, FlutterStreamHandler {
  private let motion = CMMotionManager()

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard motion.isAccelerometerAvailable else {
      return FlutterError(code: "unavailable", message: "no accelerometer", details: nil)
    }
    motion.accelerometerUpdateInterval = 1.0 / 50.0
    motion.startAccelerometerUpdates(to: OperationQueue.main) { data, _ in
      guard let data = data else { return }
      let a = data.acceleration
      events([a.x, a.y, a.z, data.timestamp * 1000.0])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    motion.stopAccelerometerUpdates()
    return nil
  }
}
