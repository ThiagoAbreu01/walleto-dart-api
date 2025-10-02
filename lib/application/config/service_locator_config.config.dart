// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:walleto_dart_api/application/config/database_connect_configuration.dart'
    as _i468;
import 'package:walleto_dart_api/application/database/database_connection.dart'
    as _i701;
import 'package:walleto_dart_api/application/database/i_database_connection.dart'
    as _i979;
import 'package:walleto_dart_api/logger/i_logger.dart' as _i1006;
import 'package:walleto_dart_api/logger/logger.dart' as _i559;
import 'package:walleto_dart_api/modules/user/controller/auth_controller.dart'
    as _i779;
import 'package:walleto_dart_api/modules/user/controller/user_controller.dart'
    as _i629;
import 'package:walleto_dart_api/modules/user/repository/i_user_repository.dart'
    as _i66;
import 'package:walleto_dart_api/modules/user/repository/user_repository.dart'
    as _i384;
import 'package:walleto_dart_api/modules/user/service/i_user_service.dart'
    as _i291;
import 'package:walleto_dart_api/modules/user/service/user_service.dart' as _i924;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  gh.factory<_i559.Logger>(() => _i559.Logger());
  gh.lazySingleton<_i979.IDatabaseConnection>(
      () => _i701.DatabaseConnection(gh<_i468.DatabaseConnectConfiguration>()));
  gh.factory<_i66.IUserRepository>(() => _i384.UserRepository(
        connection: gh<_i979.IDatabaseConnection>(),
        log: gh<_i1006.ILogger>(),
      ));
  gh.factory<_i291.IUserService>(() => _i924.UserService(
        userRepository: gh<_i66.IUserRepository>(),
        log: gh<_i1006.ILogger>(),
      ));
  gh.factory<_i629.UserController>(() => _i629.UserController(
        userService: gh<_i291.IUserService>(),
        log: gh<_i1006.ILogger>(),
      ));
  gh.factory<_i779.AuthController>(() => _i779.AuthController(
        userService: gh<_i291.IUserService>(),
        log: gh<_i1006.ILogger>(),
      ));
  return getIt;
}
