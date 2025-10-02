import 'dart:typed_data';

import 'package:walleto_dart_api/entities/enums/custom_platform.dart';
import 'package:walleto_dart_api/entities/user.dart';

abstract class IUserRepository {
  Future<User> createUser(User user);
  Future<User> loginWithEmailAndPassword(String email, String password);

  Future<void> updateUserDeviceTokenAndRefreshToken(User user);
  Future<void> updateRefreshToken(User user);
  Future<User> findById(int id);
  Future<void> updateProfileImage(User user, Uint8List data);
  Future<void> updateDeviceToken(int id, String token, CustomPlatform platform);

  Future<void> sendValidateEmailCode(String userEmail, String random4DigitCode);

  //! Send a 4-digit code to user's email, so he can update his password
  Future<void> sendRecoveryPasswordEmail(
    String userEmail,
    String random4DigitCode,
  );
  //! Change the recover code on Database, it should be equal to the code sent on user's e-mail.
  Future<void> updateRecoverTokenOnDatabase(
    String userEmail,
    String random4DigitCode,
  );
  //! This method will compare the 4 digit code received on his email with the recover code inside de DB and will return Response.ok(200) or Forbbiden.
  Future<void> validateRecoveryPasswordFourDigitCode(String email, String code);
  Future<void> changeUserPassword(String email, String newPassword);
  Future<void> updateValidateEmailCodeOnDatabase(
    String userEmail,
    String random4DigitCode,
  );
  //! This method will compare the 4 digit code received on his email with the recover code inside de DB and will return Response.ok(200) or Forbbiden.
  Future<void> validateConfirmEmailFourDigitCode(String email, String code);
  Future<String> deleteUser(int id, User contaConectada);
}
