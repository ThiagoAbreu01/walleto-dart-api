import 'package:dotenv/dotenv.dart' show load, env;
import 'package:get_it/get_it.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:walleto_dart_api/application/config/database_connect_configuration.dart';
import 'package:walleto_dart_api/application/config/service_locator_config.dart';
import 'package:walleto_dart_api/application/routers/router_configure.dart';
import 'package:walleto_dart_api/logger/app_logger.dart';
import 'package:walleto_dart_api/logger/i_logger.dart';
import 'package:walleto_dart_api/logger/logger.dart';
import 'package:walleto_dart_api/logger/logger_app_logger.dart';

class ApplicationConfig {
  Future<void> loadConfigApplication(Router router) async {
    await _loadEnv();
    _loadDatabaseConfig();
    _configLogger();
    _loadDependencies();
    _loadRoutersConfigure(router);
    // startWebSocketServer();
  }

  Future<void> _loadEnv() async => load();

  void _loadDatabaseConfig() {
    late DatabaseConnectConfiguration databaseConfig;
    databaseConfig = DatabaseConnectConfiguration(
      host: env['DATABASE_PROD_HOST'] ?? '',
      user: env['DATABASE_PROD_USER'] ?? '',
      port: env['DATABASE_PROD_PORT'] ?? '',
      password: env['DATABASE_PROD_PASSWORD'] ?? '',
      databaseName: env['DATABASE_PROD_NAME'] ?? '',
    );
    
    GetIt.I.registerSingleton(databaseConfig);
  }

  void _configLogger() {
    GetIt.I.registerLazySingleton<ILogger>(() => Logger());
    GetIt.I.registerLazySingleton<AppLogger>(() => LoggerAppLoggerImpl());
  }

  void _loadDependencies() => configureDependencies();

  void _loadRoutersConfigure(Router router) =>
      RouterConfigure(router).configure();
}
