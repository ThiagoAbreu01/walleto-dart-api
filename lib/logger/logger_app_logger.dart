import 'package:logger/logger.dart';

import 'app_logger.dart';

class LoggerAppLoggerImpl implements AppLogger {
  late final Logger logger;

  var messages = <String>[];

  LoggerAppLoggerImpl() {
    var release = true;
    assert(() {
      release = false;
      return true;
    }());
    logger = Logger(
      filter: release ? ProductionFilter() : DevelopmentFilter(),
    );
  }

  @override
  void debug(message, [error, StackTrace? stackTrace]) =>
      logger.d(message, error, stackTrace);

  @override
  void error(message, [error, StackTrace? stackTrace]) =>
      logger.e(message, error, stackTrace);

  @override
  void info(message, [error, StackTrace? stackTrace]) =>
      logger.i(message, error, stackTrace);

  @override
  void warning(message, [error, StackTrace? stackTrace]) =>
      logger.w(message, error, stackTrace);

  @override
  void append(message) {
    messages.add(message);
  }

  void closeAppend() {
    info(messages.join('\n'));
    messages = [];
  }
}
