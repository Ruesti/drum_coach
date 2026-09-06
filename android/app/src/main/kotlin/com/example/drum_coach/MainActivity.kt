package com.example.drum_coach

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "drum_coach/audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUnprocessedSupported" -> {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val supported = audioManager.getProperty(
                            AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED
                        ) == "true"
                        result.success(supported)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
