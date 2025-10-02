// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// ShelfRouterGenerator
// **************************************************************************

Router _$AuthControllerRouter(AuthController service) {
  final router = Router();
  router.add(
    'POST',
    r'/',
    service.login,
  );
  router.add(
    'POST',
    r'/register',
    service.saveUser,
  );
  router.add(
    'PATCH',
    r'/confirm',
    service.confirmLogin,
  );
  router.add(
    'PUT',
    r'/refresh',
    service.refreshToken,
  );
  router.add(
    'PUT',
    r'/send-email-confirm-code',
    service.sendEmailConfirmCode,
  );
  router.add(
    'PUT',
    r'/validate-confirm-code',
    service.validateConfirmCode,
  );
  router.add(
    'PUT',
    r'/send-email-recovery-password-code',
    service.sendPasswordRecoveryEmail,
  );
  router.add(
    'PUT',
    r'/validate-recover-password-code',
    service.validateRecoverCodeToLogin,
  );
  router.add(
    'PUT',
    r'/change-password',
    service.changeUserPassword,
  );
  return router;
}
