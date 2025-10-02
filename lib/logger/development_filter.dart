import 'package:logger/logger.dart';

class DevelopmentFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    var shouldLog = false;
    assert(() {
      if (event.level.index >= level!.index) {
        shouldLog = true;
      }
      return true;
    }());
    return shouldLog;
  }
}
