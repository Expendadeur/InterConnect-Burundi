import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
    level: Level.debug,
  );

  static void d(String message, {dynamic data}) {
    _logger.d(message, error: data);
  }

  static void i(String message, {dynamic data}) {
    _logger.i(message, error: data);
  }

  static void w(String message, {dynamic data}) {
    _logger.w(message, error: data);
  }

  static void e(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
