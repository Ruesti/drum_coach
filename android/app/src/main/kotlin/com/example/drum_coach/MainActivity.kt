package com.example.drum_coach

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var audioChannel: MethodChannel? = null
    private var deviceCallback: AudioDeviceCallback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "drum_coach/audio")
        audioChannel = channel

        // Push headphone plug/unplug events to Flutter: SoLoud's output
        // stream does not survive an Android routing change on its own.
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val callback = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(added: Array<out AudioDeviceInfo>) {
                channel.invokeMethod("audioDevicesChanged", null)
            }
            override fun onAudioDevicesRemoved(removed: Array<out AudioDeviceInfo>) {
                channel.invokeMethod("audioDevicesChanged", null)
            }
        }
        deviceCallback = callback
        audioManager.registerAudioDeviceCallback(callback, Handler(Looper.getMainLooper()))

        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUnprocessedSupported" -> {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val supported = audioManager.getProperty(
                            AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED
                        ) == "true"
                        result.success(supported)
                    }
                    "headphonesType" -> {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                        val wiredTypes = setOf(
                            AudioDeviceInfo.TYPE_WIRED_HEADSET,
                            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                            AudioDeviceInfo.TYPE_USB_HEADSET,
                            AudioDeviceInfo.TYPE_USB_DEVICE,
                        )
                        val bluetoothTypes = setOf(
                            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
                            AudioDeviceInfo.TYPE_BLE_HEADSET,
                        )
                        val type = when {
                            devices.any { it.type in wiredTypes } -> "wired"
                            devices.any { it.type in bluetoothTypes } -> "bluetooth"
                            else -> "none"
                        }
                        result.success(type)
                    }
                    "deviceInfo" -> {
                        result.success(mapOf(
                            "model" to Build.MODEL,
                            "androidVersion" to Build.VERSION.RELEASE,
                        ))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        deviceCallback?.let {
            (getSystemService(Context.AUDIO_SERVICE) as AudioManager)
                .unregisterAudioDeviceCallback(it)
        }
        deviceCallback = null
        super.onDestroy()
    }
}
