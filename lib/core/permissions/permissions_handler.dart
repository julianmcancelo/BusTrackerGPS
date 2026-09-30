import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class AppPermissionsHandler {
  static Future<bool> checkAndRequestLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<bool> requestNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    }
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    if (await Permission.camera.isGranted) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestMicrophonePermission() async {
    if (await Permission.microphone.isGranted) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
}
