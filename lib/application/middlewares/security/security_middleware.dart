// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';
import 'package:walleto_dart_api/application/helpers/jwt_helper.dart';
import 'package:walleto_dart_api/application/middlewares/middlewares.dart';
import 'package:walleto_dart_api/application/middlewares/security/security_skip_url.dart';
import 'package:walleto_dart_api/logger/i_logger.dart';

class SecurityMiddleware extends Middlewares {
  final ILogger log;
  final skipUrl = <SecuritySkipUrl>[
    SecuritySkipUrl(url: '/auth/', method: 'POST'),
    SecuritySkipUrl(url: '/auth/register', method: 'POST'),
    SecuritySkipUrl(url: '/auth/refresh', method: 'PUT'),
    SecuritySkipUrl(url: '/auth/send-recover-email', method: 'PUT'),
    SecuritySkipUrl(
      url: '/auth/send-email-recovery-password-code',
      method: 'PUT',
    ),
    SecuritySkipUrl(url: '/auth/validate-recover-password-code', method: 'PUT'),
    SecuritySkipUrl(url: '/auth/change-password', method: 'PUT'),
  ];

  SecurityMiddleware({required this.log});

  @override
  Future<Response> execute(Request request) async {
    try {
      // log.info('/${request.url.path}' + ' | ' + request.method);

      if (skipUrl.contains(
        SecuritySkipUrl(url: '/${request.url.path}', method: request.method),
      )) {
        return innerHandler(request);
      }

      // log.info('OutHandler');

      final authHeader = request.headers['Authorization'];

      if (authHeader == null || authHeader.isEmpty) {
        throw JwtException.invalidToken;
      }

      final authHeaderContent = authHeader.split(' ');

      if (authHeaderContent[0] != 'Bearer') {
        throw JwtException.invalidToken;
      }

      final authorizationToken = authHeaderContent[1];
      final claims = JwtHelper.getClaims(authorizationToken);

      if (request.url.path != 'auth/refresh') {
        claims.validate();
      }

      final claimsMap = claims.toJson();
      final userID =
          claimsMap['sub']; //TODO -> ToDo apenas para localizar variáveis globais do BackEnd.
      final hashIDObra = claimsMap['hashIDObra'];

      if (userID == null) {
        throw JwtException.invalidToken;
      }
      final securityHeaders = {
        'user': userID,
        'access_token': authorizationToken,
        'hashIDObra': hashIDObra,
      };

      return innerHandler(request.change(headers: securityHeaders));
    } on JwtException catch (e, s) {
      log.error('Erro ao validar token JWT', e, s);
      return Response.forbidden(jsonEncode({'message': 'Login Expirado.'}));
    } catch (e, s) {
      log.error('Internal Server Error', e, s);
      return Response.forbidden(jsonEncode({}));
    }
  }
}
