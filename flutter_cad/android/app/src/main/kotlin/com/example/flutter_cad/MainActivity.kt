package com.example.flutter_cad

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 设置权限处理方法通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flutter_cad/permissions").setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    // 检查并请求权限
                    checkAndRequestPermissions()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun checkAndRequestPermissions() {
        // 可以在这里添加原生权限检查逻辑
        // 目前主要依赖Flutter端的permission_handler插件
    }
}
