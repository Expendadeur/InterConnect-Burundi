import 'package:flutter/services.dart';

class RingtoneService {
  static const MethodChannel _channel = MethodChannel('com.interconnect.burundi/ringtone');

  static Future<void> play() async {
    try {
      await _channel.invokeMethod('playRingtone');
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopRingtone');
    } catch (_) {}
  }
}
