import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceMetadata {
  static Future<Map<String, String>>? _cached;
  static Future<Map<String, String>> headers() => _cached ??= _load();

  static Future<Map<String, String>> _load() async {
    try {
      final info = DeviceInfoPlugin();
      final package = await PackageInfo.fromPlatform();
      var name = Platform.operatingSystem;
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        name = '${android.manufacturer} ${android.model}';
      } else if (Platform.isIOS) {
        name = (await info.iosInfo).utsname.machine;
      }
      return {
        'X-Device-Name': name,
        'X-Device-Platform': Platform.operatingSystem,
        'X-App-Version': package.version,
      };
    } catch (_) {
      return {'X-Device-Platform': Platform.operatingSystem};
    }
  }
}
