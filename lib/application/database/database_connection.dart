import 'package:injectable/injectable.dart';
import 'package:mysql1/mysql1.dart';
import 'package:walleto_dart_api/application/config/database_connect_configuration.dart';
import 'i_database_connection.dart';

@LazySingleton(as: IDatabaseConnection)
class DatabaseConnection implements IDatabaseConnection {
  final DatabaseConnectConfiguration _configuration;

  DatabaseConnection(this._configuration);

  @override
  Future<MySqlConnection> openConnection() async {
    var connection = await MySqlConnection.connect(
      ConnectionSettings(
        host: _configuration.host,
        port: int.parse(_configuration.port),
        user: _configuration.user,
        password: _configuration.password,
        db: _configuration.databaseName,
        timeout: const Duration(seconds: 35),
      ),
    );
    return connection;
  }
}
