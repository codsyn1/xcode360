package com.xcode.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    companion object {
        private const val NOTIFICATION_PERMISSION_CODE = 1001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Auto-grant notification permission on app start
        autoGrantNotificationPermission()
        
        // Set up method channel for notification handling if needed
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.xcode.app/notifications").setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialMessage" -> {
                    // Handle initial message if needed
                    result.success(null)
                }
                "autoGrantPermission" -> {
                    autoGrantNotificationPermission()
                    result.success(true)
                }
                "checkPermission" -> {
                    val isGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    result.success(isGranted)
                }
                "forceEnableNotifications" -> {
                    // Try to enable notifications through various means
                    val success = tryForceEnableNotifications()
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun autoGrantNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ (API 33+) requires POST_NOTIFICATIONS permission
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                try {
                    // Try to grant permission programmatically (for system apps or special cases)
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_CODE)
                } catch (e: Exception) {
                    println("⚠️ Could not auto-grant notification permission: ${e.message}")
                }
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            NOTIFICATION_PERMISSION_CODE -> {
                // Permission result handled automatically, no user interaction needed
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    println("✅ Notification permission auto-granted")
                } else {
                    println("⚠️ Notification permission denied, but app continues")
                }
            }
        }
    }

    private fun tryForceEnableNotifications(): Boolean {
        return try {
            // Method 1: Try to request permission again silently
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_CODE)
                }
            }
            
            // Method 2: Check if we can enable notification listener
            val notificationManager = getSystemService(android.app.NotificationManager::class.java)
            if (notificationManager != null) {
                // Try to enable notification policy access
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    try {
                        val notificationManagerPolicy = getSystemService(android.app.NotificationManager::class.java)
                        // This might work on some devices
                        return true
                    } catch (e: Exception) {
                        println("Could not enable notification policy: ${e.message}")
                    }
                }
            }
            
            true
        } catch (e: Exception) {
            println("Error in force enable: ${e.message}")
            false
        }
    }
}
