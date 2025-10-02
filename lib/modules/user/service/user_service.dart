// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:walleto_dart_api/application/exceptions/credentials_not_found_exception.dart';
import 'package:walleto_dart_api/application/exceptions/database_exception.dart';
import 'package:walleto_dart_api/application/exceptions/invalid_new_password_exception.dart';
import 'package:walleto_dart_api/application/exceptions/invalid_recover_4digit_code_exception.dart';
import 'package:walleto_dart_api/application/exceptions/user_email_not_yet_confirmed_exception.dart';
import 'package:walleto_dart_api/application/exceptions/user_not_found_exception.dart';
import 'package:walleto_dart_api/application/exceptions/user_service_exception.dart';
import 'package:walleto_dart_api/application/helpers/jwt_helper.dart';
import 'package:walleto_dart_api/application/helpers/random_hash_coder_helper.dart';
import 'package:walleto_dart_api/entities/enums/custom_platform.dart';
import 'package:walleto_dart_api/entities/user.dart';
import 'package:walleto_dart_api/logger/i_logger.dart';
import 'package:mailer/mailer.dart';

import 'package:walleto_dart_api/modules/user/repository/i_user_repository.dart';
import 'package:walleto_dart_api/modules/user/service/i_user_service.dart';
import 'package:walleto_dart_api/modules/user/view_models/refresh_token_view_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/register_user_input_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/user_confirm_input_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/user_refresh_token_input_view_model.dart';

@Injectable(as: IUserService)
class UserService implements IUserService {
  final IUserRepository userRepository;
  final ILogger log;
  UserService({required this.userRepository, required this.log});

  @override
  Future<void> changeUserPassword(String email, String newPassword) async {
    if (newPassword.length < 6) {
      throw InvalidNewPasswordException(
        message: 'A nova senha deve conter pelo menos 6 caracteres.',
      );
    } else if (newPassword.isEmpty) {
      throw InvalidNewPasswordException(message: 'A senha não pode ser vazia.');
    }

    return await userRepository.changeUserPassword(email, newPassword);
  }

  @override
  Future<String> confirmLogin(UserConfirmInputModel inputModel) async {
    //! Retorna User completo.
    final userByID = await findById(inputModel.userID);
    final userWithToken = userByID.copyWith(
      id: inputModel.userID,
      refreshToken: JwtHelper.refreshToken(inputModel.accessToken),
      iosToken: inputModel.iosDeviceToken,
      androidToken: inputModel.androidDeviceToken,
    );
    
    await userRepository.updateUserDeviceTokenAndRefreshToken(userWithToken);
    return userWithToken.refreshToken!;
  }

  @override
  Future<User> createUser(RegisterUserInputModel user) async {
    final userEntity = User(
      id: null,
      nomeUsuario: user.nome,
      email: user.email,
      cpf: user.cpf,
      telefone: user.telefone,
      passwordCrypto: user.password,
      dataCriacaoConta: DateTime.now().toUtc(),
    );
    return userRepository.createUser(userEntity);
  }

  @override
  Future<String> deleteUser(int id, User contaConectada) =>
      userRepository.deleteUser(id, contaConectada);

  @override
  Future<User> findById(int id) => userRepository.findById(id);

  @override
  Future<User> loginWithEmailAndPassword(String email, String password) =>
      userRepository.loginWithEmailAndPassword(email, password);

  @override
  Future<void> recoverPassword(String userEmail) async {
    String random4DigitCode = RandomHashCoderHelper.getRandomNumericString(4);

    try {
      await userRepository.updateRecoverTokenOnDatabase(
        userEmail,
        random4DigitCode,
      );
      await userRepository.sendRecoveryPasswordEmail(
        userEmail,
        random4DigitCode,
      );
    } on DatabaseException {
      rethrow;
    } on UserNotFoundException {
      rethrow;
    } on CredentialsNotFoundException {
      rethrow;
    }
  }

  @override
  Future<RefreshTokenViewModel> refreshToken(
    UserRefreshTokenInputModel model,
  ) async {
    _validateRefreshToken(model);

    final newAccessToken = JwtHelper.generateJWT(model.userID);
    final newRefreshToken = JwtHelper.refreshToken(
      newAccessToken.replaceAll('Bearer ', ''),
    );

    final user = User(id: model.userID, refreshToken: newRefreshToken);
    await userRepository.updateRefreshToken(user);
    return RefreshTokenViewModel(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );
  }

  @override
  Future<void> validateRecoveryPasswordFourDigitCode(
    String email,
    String code,
  ) async {
    if (code == '' || code.length < 4 || code.length > 4) {
      throw InvalidRecover4digitCodeException(
        message: 'Código de validação inválido.',
      );
    }
    return userRepository.validateRecoveryPasswordFourDigitCode(email, code);
  }

  void _validateRefreshToken(UserRefreshTokenInputModel model) {
    try {
      final refreshToken = model.refreshToken.split(' ');
      if (refreshToken.length != 2 || refreshToken.first != 'Bearer') {
        log.error('Refresh Token inválido.');
        throw UserServiceException(message: 'Refresh Token inválido.');
      }
      final refreshTokenClaim = JwtHelper.getClaims(refreshToken.last);
      refreshTokenClaim.validate(issuer: model.accessToken);
    } on UserServiceException {
      rethrow;
    } on JwtException catch (e, s) {
      log.error('Erro ao validar Refresh Token', e, s);
      throw UserServiceException(message: 'Refresh Token inválido.');
    } catch (e) {
      throw UserServiceException(message: 'Erro ao validar Refresh Token.');
    }
  }

  @override
  Future<void> updateDeviceToken(
    int id,
    String token,
    CustomPlatform platform,
  ) => userRepository.updateDeviceToken(id, token, platform);
  @override
  Future<void> updateProfileImage(User user, Uint8List data) =>
      userRepository.updateProfileImage(user, data);
  @override
  Future<void> updateRefreshToken(User user) =>
      userRepository.updateRefreshToken(user);

  @override
  Future<void> validateEmail(String userEmail) async {
    String random4DigitCode = RandomHashCoderHelper.getRandomNumericString(4);

    try {
      await userRepository.updateValidateEmailCodeOnDatabase(
        userEmail,
        random4DigitCode,
      );
      await userRepository.sendValidateEmailCode(userEmail, random4DigitCode);
    } on DatabaseException {
      rethrow;
    } on UserNotFoundException {
      rethrow;
    } on MailerException {
      rethrow;
    } on CredentialsNotFoundException {
      rethrow;
    } on UserEmailNotYetConfirmedException {
      rethrow;
    }
  }

  @override
  Future<void> validateConfirmEmailFourDigitCode(
    String email,
    String code,
  ) async {
    if (code == '' || code.length < 4 || code.length > 4) {
      throw InvalidRecover4digitCodeException(
        message: 'Código de validação inválido.',
      );
    }
    return userRepository.validateConfirmEmailFourDigitCode(email, code);
  }
}
