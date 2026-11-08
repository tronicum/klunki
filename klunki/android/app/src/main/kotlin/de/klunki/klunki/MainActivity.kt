package de.klunki.klunki

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
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
        // KLD-121 follow-up: accelerometer samples for shake to roll
        // (lib/platform/shake.dart); the sensor runs only while Dart listens.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "klunki/accelerometer")
            .setStreamHandler(AccelerometerStream(getSystemService(Context.SENSOR_SERVICE) as SensorManager))
    }
}

/** Sends `[x, y, z, ms]` (acceleration incl. gravity in g, a timestamp in
 *  milliseconds) about 50 times a second (SENSOR_DELAY_GAME) while listened
 *  to; the error "unavailable" without an accelerometer. No permission needed. */
private class AccelerometerStream(private val sensors: SensorManager) : EventChannel.StreamHandler {
    private var listener: SensorEventListener? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        if (sensor == null) {
            events.error("unavailable", "no accelerometer", null)
            return
        }
        val l = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                val g = SensorManager.GRAVITY_EARTH.toDouble()
                events.success(
                    doubleArrayOf(
                        event.values[0] / g,
                        event.values[1] / g,
                        event.values[2] / g,
                        event.timestamp / 1_000_000.0,
                    ),
                )
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        sensors.registerListener(l, sensor, SensorManager.SENSOR_DELAY_GAME)
        listener = l
    }

    override fun onCancel(arguments: Any?) {
        listener?.let { sensors.unregisterListener(it) }
        listener = null
    }
}
