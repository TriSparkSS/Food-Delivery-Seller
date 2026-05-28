package com.qadam.foodseller.qadam_food_seller

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "qadam_food_seller/device"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceIdentity" -> {
                    val deviceToken = Settings.Secure.getString(
                        contentResolver,
                        Settings.Secure.ANDROID_ID
                    ) ?: "unknown-android-device"

                    result.success(
                        mapOf(
                            "device_type" to "Android",
                            "device_token" to deviceToken,
                            "fcm_token" to null
                        )
                    )
                }

                else -> result.notImplemented()
            }
        }
    }
}
