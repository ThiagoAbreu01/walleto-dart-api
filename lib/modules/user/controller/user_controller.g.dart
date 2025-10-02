// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_controller.dart';

// **************************************************************************
// ShelfRouterGenerator
// **************************************************************************

Router _$UserControllerRouter(UserController service) {
  final router = Router();
  router.add(
    'GET',
    r'/',
    service.findByToken,
  );
  router.add(
    'POST',
    r'/update-image',
    service.updateImageURL,
  );
  router.add(
    'DELETE',
    r'/delete-account/<id>',
    service.deleteUser,
  );
  return router;
}
