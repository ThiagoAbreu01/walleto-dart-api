import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:walleto_dart_api/application/middlewares/middlewares.dart';

class CorsMiddlewares extends Middlewares {
  final Map<String, String> headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': '*',
  };

  @override
  Future<Response> execute(Request request) async {
    if (request.method == 'OPTIONS') {
      return Response(HttpStatus.ok, headers: headers);
    }

    final response = await innerHandler(request);

    return response.change(headers: headers);
  }
}
