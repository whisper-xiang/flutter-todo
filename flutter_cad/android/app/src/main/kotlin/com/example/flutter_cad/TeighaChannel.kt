package com.example.flutter_cad

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.io.File

class TeighaChannel(private val context: Context) : MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "teigha_sdk"
        private const val TAG = "TeighaChannel"
        
        // Load native library
        init {
            try {
                System.loadLibrary("teigha_sdk_jni")
            } catch (e: UnsatisfiedLinkError) {
                // Log error for debugging
                android.util.Log.e(TAG, "Failed to load Teigha SDK native library: ${e.message}")
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                try {
                    initializeSDK()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("INIT_ERROR", "Failed to initialize Teigha SDK", e.message)
                }
            }
            
            "renderDwgToImage" -> {
                try {
                    val filePath = call.argument<String>("filePath")
                    val width = call.argument<Int>("width") ?: 1024
                    val height = call.argument<Int>("height") ?: 768
                    val format = call.argument<String>("format") ?: "png"
                    
                    if (filePath == null) {
                        result.error("INVALID_ARGS", "File path is required", null)
                        return
                    }
                    
                    val imageData = renderDwgToImageNative(filePath, width, height, format)
                    if (imageData != null) {
                        result.success(imageData)
                    } else {
                        result.error("RENDER_ERROR", "Failed to render DWG file", null)
                    }
                } catch (e: Exception) {
                    result.error("RENDER_ERROR", "Failed to render DWG file: ${e.message}", e.message)
                }
            }
            
            "getDwgInfo" -> {
                try {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGS", "File path is required", null)
                        return
                    }
                    
                    val info = getDwgInfoNative(filePath)
                    result.success(info)
                } catch (e: Exception) {
                    result.error("INFO_ERROR", "Failed to get DWG info: ${e.message}", e.message)
                }
            }
            
            "getLayers" -> {
                try {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGS", "File path is required", null)
                        return
                    }
                    
                    val layers = getLayersNative(filePath)
                    result.success(layers)
                } catch (e: Exception) {
                    result.error("LAYERS_ERROR", "Failed to get layers: ${e.message}", e.message)
                }
            }
            
            "cleanup" -> {
                try {
                    cleanupSDK()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("CLEANUP_ERROR", "Failed to cleanup Teigha SDK", e.message)
                }
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initializeSDK() {
        // Initialize Teigha SDK
        if (!initializeTeighaNative()) {
            throw Exception("Failed to initialize Teigha SDK")
        }
    }

    private fun cleanupSDK() {
        // Cleanup Teigha SDK resources
        cleanupTeighaNative()
    }

    // Native methods - these will be implemented in C++
    private external fun initializeTeighaNative(): Boolean
    private external fun cleanupTeighaNative()
    private external fun renderDwgToImageNative(filePath: String, width: Int, height: Int, format: String): ByteArray?
    private external fun getDwgInfoNative(filePath: String): Map<String, Any>?
    private external fun getLayersNative(filePath: String): List<String>?

    companion object {
        fun setup(flutterEngine: FlutterEngine, context: Context) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
                .setMethodCallHandler(TeighaChannel(context))
        }
    }
}
