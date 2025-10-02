import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:walleto_dart_api/application/exceptions/database_exception.dart';
import 'package:walleto_dart_api/application/exceptions/user_not_found_exception.dart';
import 'package:walleto_dart_api/entities/user.dart';
import 'package:walleto_dart_api/logger/i_logger.dart';
import 'package:mime/mime.dart';
import 'package:walleto_dart_api/modules/user/service/i_user_service.dart';

part 'user_controller.g.dart';

@Injectable()
class UserController {
  final IUserService userService;
  final ILogger log;
  UserController({required this.userService, required this.log});

  @Route.get('/')
  Future<Response> findByToken(Request request) async {
    try {
      final user = int.parse(request.headers['user']!);
      final userData = await userService.findById(user);
      return Response.ok(jsonEncode(userData.toMap()));
    } on UserNotFoundException catch (e) {
      return Response.forbidden(jsonEncode({'message': e.message}));
    } catch (e, s) {
      log.error('Erro ao buscar usuário.', e, s);
      return Response.forbidden(
        jsonEncode({'message': 'Erro ao buscar usuário.'}),
      );
    }
  }

  @Route.post('/update-image')
  Future<Response> updateImageURL(Request request) async {
    try {
      final contentType = request.headers['content-type'];
      if (contentType == null || !contentType.contains('multipart/form-data')) {
        return Response.forbidden(jsonEncode({'message': 'Invalid request'}));
      }

      final user = int.parse(request.headers['user']!);

      User contaConectada = await userService.findById(user);

      final boundary = contentType.split('boundary=')[1];
      final transformer = MimeMultipartTransformer(boundary);
      final parts = await transformer.bind(request.read()).toList();

      for (var part in parts) {
        final contentDisposition = part.headers['content-disposition'];
        // ignore: unused_local_variable
        final mimeType = part.headers['content-type'];
        if (contentDisposition == null) continue;

        final fileContent = await part.fold<List<int>>(
          [],
          (previous, element) => previous..addAll(element),
        );

        final Uint8List conteudoDoArquivo = Uint8List.fromList(
          fileContent,
        ); // Convert to Uint8List

        await userService.updateProfileImage(contaConectada, conteudoDoArquivo);

        return Response.ok(
          jsonEncode('{"message": "Imagem atualizada com sucesso."}'),
        );
      }
      return Response.ok(
        jsonEncode('{"message": "Imagem atualizada com sucesso."}'),
      );
    } on DatabaseException catch (e) {
      log.error(e.message);
      return Response.forbidden(jsonEncode({'message': e.message}));
    } on FileSystemException catch (e) {
      log.error(e.message);
      return Response.forbidden(jsonEncode({'message': e.message}));
    } catch (e, s) {
      log.error('Erro ao atualizar imagem.', e, s);
      return Response.forbidden(
        jsonEncode({'message': 'Erro ao atualizar imagem.'}),
      );
    }
  }

  // String generatePresignedUrl({
  //   required String bucketName,
  //   required String file,
  //   required String region,
  // }) {
  //   final encodedNameFile = Uri.encodeComponent(file);
  //   final url = 'https://$bucketName.s3.$region.amazonaws.com/$encodedNameFile';
  //   return url;
  // }

  @Route.delete('/delete-account/<id>')
  Future<Response> deleteUser(Request request, String id) async {
    try {
      final userId = int.parse(id);
      final User contaConectada = await userService.findById(userId);
      final response = await userService.deleteUser(userId, contaConectada);
      return Response.ok(jsonEncode({'message': response}));
    } on UserNotFoundException catch (e) {
      return Response.forbidden(jsonEncode({'message': e.message}));
    } catch (e, s) {
      log.error('Erro ao deletar usuário.', e, s);
      return Response.forbidden(
        jsonEncode({'message': 'Erro ao deletar usuário.'}),
      );
    }
  }

  Router get router => _$UserControllerRouter(this);
}
