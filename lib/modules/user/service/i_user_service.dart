import 'dart:typed_data';

import 'package:walleto_dart_api/entities/enums/custom_platform.dart';
import 'package:walleto_dart_api/entities/user.dart';
import 'package:walleto_dart_api/modules/user/view_models/refresh_token_view_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/register_user_input_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/user_confirm_input_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/user_refresh_token_input_view_model.dart';

abstract class IUserService {
  Future<User> createUser(RegisterUserInputModel user);
  Future<User> loginWithEmailAndPassword(String email, String password);
  Future<String> confirmLogin(UserConfirmInputModel userConfirmInputModel);
  Future<RefreshTokenViewModel> refreshToken(
    UserRefreshTokenInputModel userRefreshTokenInputModel,
  );
  Future<User> findById(int id);
  Future<void> validateEmail(String email);

  Future<void> recoverPassword(String email);
  Future<void> validateRecoveryPasswordFourDigitCode(String email, String code);
  Future<void> changeUserPassword(String email, String newPassword);
  // Future<void> validateConfirmEmailFourDigitCode(String email, String code);
  Future<String> deleteUser(int id, User contaConectada);
  Future<void> updateProfileImage(User user, Uint8List data);
  Future<void> updateDeviceToken(int id, String token, CustomPlatform platform);
  Future<void> updateRefreshToken(User user);
  Future<void> validateConfirmEmailFourDigitCode(
    String userEmail,
    String random4DigitCode,
  );
}
