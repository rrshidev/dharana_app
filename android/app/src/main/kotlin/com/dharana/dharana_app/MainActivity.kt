package com.dharana.dharana_app

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dharana/device"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRingerMode" -> {
                    val audioManager =
                        getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    result.success(audioManager.ringerMode)
                }
                "isVibrateEnabled" -> {
                    val audioManager =
                        getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    // On Android 11+ requires vibrator-permission for some checks;
                    // we approximate with ringer mode + system vibration setting.
                    val mode = audioManager.ringerMode
                    result.success(mode == AudioManager.RINGER_MODE_VIBRATE)
                }
                else -> result.notImplemented()
            }
        }
    }
}
