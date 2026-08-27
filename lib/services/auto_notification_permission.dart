import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AutoNotificationPermission {
  static const MethodChannel _channel = MethodChannel('com.xcode.app/notifications');

  /// Automatically grant notification permission without showing dialog
  static Future<bool> grantPermissionSilently() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true; // iOS and web don't have this issue
    }

    try {
      // Call native method to attempt silent permission grant
      final result = await _channel.invokeMethod('autoGrantPermission');
      return result == true;
    } catch (e) {
      print('❌ Error in silent permission grant: $e');
      return false;
    }
  }

  /// Check if notification permission is available
  static Future<bool> isPermissionGranted() async {
    try {
      final result = await _channel.invokeMethod('checkPermission');
      return result == true;
    } catch (e) {
      print('❌ Error checking permission: $e');
      return false;
    }
  }

  /// Force enable notifications through system settings (if possible)
  static Future<bool> forceEnableNotifications() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }

    try {
      final result = await _channel.invokeMethod('forceEnableNotifications');
      return result == true;
    } catch (e) {
      print('❌ Error forcing notifications: $e');
      return false;
    }
  }
}
