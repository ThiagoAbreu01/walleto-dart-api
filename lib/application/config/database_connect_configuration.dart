// ignore_for_file: public_member_api_docs, sort_constructors_first
class DatabaseConnectConfiguration {
  final String host;
  final String user;
  final String port;
  final String password;
  final String databaseName;
  DatabaseConnectConfiguration({
    required this.host,
    required this.user,
    required this.port,
    required this.password,
    required this.databaseName,
  });
}
