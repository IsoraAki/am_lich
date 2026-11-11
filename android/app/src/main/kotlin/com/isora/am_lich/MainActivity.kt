package com.isora.am_lich

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "am_lich/widget")
            .setMethodCallHandler { call, result ->
                if (call.method != "requestPin") {
                    result.notImplemented()
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val manager = AppWidgetManager.getInstance(this)
                    val supported = manager.isRequestPinAppWidgetSupported
                    if (supported) {
                        manager.requestPinAppWidget(
                            ComponentName(this, LunarWidgetProvider::class.java), null, null
                        )
                    }
                    result.success(supported)
                } else {
                    result.success(false)
                }
            }
    }
}
