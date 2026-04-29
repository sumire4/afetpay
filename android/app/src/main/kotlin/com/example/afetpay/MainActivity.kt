package com.example.afetpay

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val HCE_CHANNEL = "com.afetpay/hce"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HCE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "hce_start" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.error("INVALID_ARG", "uri boş olamaz", null)
                            return@setMethodCallHandler
                        }
                        // Payload'u HCE servisine set et
                        AfetPayHceService.setPayloadUri(uri)
                        // Servisi başlat (zaten manifest'te kayıtlı, NFC stack tarafından
                        // otomatik çağrılır; ama explicit start ile foreground'a alıyoruz)
                        val intent = Intent(this, AfetPayHceService::class.java)
                        startService(intent)
                        result.success(null)
                    }

                    "hce_stop" -> {
                        AfetPayHceService.ndefFile = null
                        stopService(Intent(this, AfetPayHceService::class.java))
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
