package de.klunki.klunki

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // KLD-120: keep the screen on while a network game runs
        // (lib/app/screen_awake.dart); a locked phone drops the connection.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "klunki/screen").setMethodCallHandler { call, result ->
            val on = call.arguments as? Boolean
            if (call.method != "keepOn" || on == null) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (on) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
            result.success(null)
        }
    }
}
