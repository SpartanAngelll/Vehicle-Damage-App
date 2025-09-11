package com.example.vehicle_damage_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.multidex.MultiDexApplication

class MainActivity: FlutterActivity() {
    private val CHANNEL = "api_keys"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getOpenAIApiKey" -> {
                    val apiKey = BuildConfig.OPENAI_API_KEY
                    result.success(apiKey)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

class MyApplication : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
    }
}