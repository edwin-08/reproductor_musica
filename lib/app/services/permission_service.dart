import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (Platform.isAndroid) {
      if (sdkInt >= 30) {
        if (sdkInt >= 33) {
          if (!await Permission.audio.isGranted) {
            final status = await Permission.audio.request();
            if (!status.isGranted) return false;
          }
        }
        if (!await Permission.manageExternalStorage.isGranted) {
          final status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) return false;
        }
      } else {
        if (!await Permission.storage.isGranted) {
          final status = await Permission.storage.request();
          if (!status.isGranted) return false;
        }
      }
    }
    return true;
  }

  static Future<bool> checkStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    } else {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
  }
}
