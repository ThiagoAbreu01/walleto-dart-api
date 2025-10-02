// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:walleto_dart_api/application/exceptions/credentials_not_found_exception.dart';
import 'package:walleto_dart_api/application/exceptions/database_exception.dart';
import 'package:walleto_dart_api/application/exceptions/invalid_new_password_exception.dart';
import 'package:walleto_dart_api/application/exceptions/invalid_recover_4digit_code_exception.dart';
import 'package:walleto_dart_api/application/exceptions/user_exists_exception.dart';
import 'package:walleto_dart_api/application/exceptions/user_not_found_exception.dart';
import 'package:walleto_dart_api/application/helpers/jwt_helper.dart';
import 'package:walleto_dart_api/entities/user.dart';
import 'package:walleto_dart_api/logger/i_logger.dart';
import 'package:mailer/mailer.dart';

import 'package:walleto_dart_api/modules/user/service/i_user_service.dart';
import 'package:walleto_dart_api/modules/user/view_models/change_password_view_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/login_view_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/recover_password_view_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/register_user_input_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/user_confirm_input_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/user_refresh_token_input_view_model.dart';
import 'package:walleto_dart_api/modules/user/view_models/validate_four_digit_code_view_model.dart';

part 'auth_controller.g.dart';

@Injectable()
class AuthController {
  final IUserService userService;
  final ILogger log;
  AuthController({required this.userService, required this.log});

  @Route.post('/')
  Future<Response> login(Request request) async {
    try {
      final loginViewModel = LoginViewModel(await request.readAsString());

      User? user;
      user = await userService.loginWithEmailAndPassword(
        loginViewModel.email,
        loginViewModel.password,
      );

      return Response.ok(
        jsonEncode({'access_token': JwtHelper.generateJWT(user.id!)}),
      );
    } on UserNotFoundException catch (e, s) {
      log.error('Usuário ou senha inválidos', e, s);
      return Response.forbidden(
        jsonEncode({"message": "Usuário ou senha inválidos."}),
      );
    }
    //  on UserEmailNotYetConfirmedException catch (e, s) {
    //   log.error('Erro ao fazer Login.', e, s);
    //   return Response.forbidden(jsonEncode({"message": e.message}));
    // }
    on SocketException {
      return Response.forbidden(
        jsonEncode({"message": "Erro ao realizar Login."}),
      );
    }
  }

  @Route.post('/register')
  Future<Response> saveUser(Request request) async {
    try {
      final userModel = RegisterUserInputModel(await request.readAsString());

      await userService.createUser(userModel);
      return Response.ok(
        jsonEncode({"message": "Cadastro realizado com sucesso!"}),
      );
    } on UserExistsException {
      return Response.forbidden(
        jsonEncode({"message": "Usuário já cadastrado na base de dados."}),
      );
    } catch (e, s) {
      log.error('Erro ao cadastrar usuário', e, s);
      return Response.forbidden(
        jsonEncode({"message": "Houve um erro ao cadastrar usuário."}),
      );
    }
  }

  @Route('PATCH', '/confirm')
  Future<Response> confirmLogin(Request request) async {
    final user = int.parse(request.headers['user']!);
    final token = JwtHelper.generateJWT(user).replaceAll('Bearer ', '');
    final inputModel = UserConfirmInputModel(
      userID: user,
      accessToken: token,
      data: await request.readAsString(),
    );

    final refreshToken = await userService.confirmLogin(inputModel);
    return Response.ok(
      jsonEncode({
        "access_token": 'Bearer $token',
        "refresh_token": refreshToken,
      }),
    );
  }

  @Route.put('/refresh')
  Future<Response> refreshToken(Request request) async {
    try {
      final user = int.parse(request.headers['user']!);
      final accessToken = request.headers['access_token']!;
      final model = UserRefreshTokenInputModel(
        userID: user,
        accessToken: accessToken,
        dataRequest: await request.readAsString(),
      );
      final userRefreshToken = await userService.refreshToken(model);

      return Response.ok(
        jsonEncode({
          'access_token': userRefreshToken.accessToken,
          'refresh_token': userRefreshToken.refreshToken,
        }),
      );
    } catch (e) {
      return Response.forbidden(
        jsonEncode({'message': 'Erro ao atualizar Access Token'}),
      );
    }
  }

  //! Confirm Email
  @Route.put('/send-email-confirm-code')
  Future<Response> sendEmailConfirmCode(Request request) async {
    try {
      final dataRequest = await request.readAsString();
      final viewModel = RecoverPasswordViewModel(dataRequest);
      await userService.validateEmail(viewModel.email);
      return Response.ok(jsonEncode({"message": 'Sucesso ao enviar e-mail'}));
    } on DatabaseException {
      return Response.forbidden(
        jsonEncode({
          'message': 'Erro ao gerar código de token para alterar a senha.',
        }),
      );
    } on MailerException {
      return Response.forbidden(
        jsonEncode({
          'message': 'Erro ao enviar código de token para o email selecionado.',
        }),
      );
    } on UserNotFoundException {
      return Response.forbidden(
        jsonEncode({
          'message': 'Nenhuma conta foi encontrada com o e-mail digitado.',
        }),
      );
    } on CredentialsNotFoundException {
      return Response.forbidden(
        jsonEncode({
          'message':
              'Houve um erro inesperado ao tentar enviar seu e-mail de recuperação',
        }),
      );
    }
  }

  @Route.put('/validate-confirm-code')
  Future<Response> validateConfirmCode(Request request) async {
    try {
      var dataRequest = await request.readAsString();

      var dataViewModel = ValidateFourDigitCodeViewModel(dataRequest);

      await userService.validateConfirmEmailFourDigitCode(
        dataViewModel.email,
        dataViewModel.code,
      );

      return Response.ok(
        jsonEncode({'message': 'Código validado com sucesso!'}),
      );
    } on InvalidRecover4digitCodeException catch (e, s) {
      log.error('O código inserido é inválido.', e, s);
      return Response.forbidden(
        jsonEncode({'message': 'Código de confirmação incorreto.'}),
      );
    } on DatabaseException catch (e, s) {
      log.error(
        'Erro ao validar o seu código, por favor, tente novamente em alguns instantes.',
        e.message,
        s,
      );
      return Response.forbidden(
        jsonEncode({
          'message':
              'Houve um erro de conexão com o servidor, tente novamente em alguns instantes.',
        }),
      );
    } on UserNotFoundException catch (e, s) {
      log.error(
        'Não foi encontrado nenhum usuário com o e-mail digitado.',
        e,
        s,
      );
      return Response.notFound(
        jsonEncode({
          'message': 'Não foi encontrado nenhum usuário com o e-mail digitado.',
        }),
      );
    }
  }

  @Route.put('/send-email-recovery-password-code')
  Future<Response> sendPasswordRecoveryEmail(Request request) async {
    try {
      final dataRequest = await request.readAsString();
      final viewModel = RecoverPasswordViewModel(dataRequest);
      await userService.recoverPassword(viewModel.email);
      return Response.ok(jsonEncode({"message": 'Sucesso ao enviar e-mail'}));
    } on DatabaseException catch (e, s) {
      log.error('Erro ao gerar código de token para alterar a senha.', e, s);
      return Response.forbidden(
        jsonEncode({
          'message': 'Erro ao gerar código de token para alterar a senha.',
        }),
      );
    } on MailerException catch (e, s) {
      log.error(
        'Houve um erro ao enviar código de token para o email selecionado',
        e,
        s,
      );
      return Response.forbidden(
        jsonEncode({
          'message': 'Erro ao enviar código de token para o email selecionado.',
        }),
      );
    } on UserNotFoundException catch (e, s) {
      log.error('Usuário não encontrado para envio de email', e, s);
      return Response.forbidden(
        jsonEncode({
          'message': 'Nenhuma conta foi encontrada com o e-mail digitado.',
        }),
      );
    } on CredentialsNotFoundException catch (e, s) {
      log.error('Credenciais não encontradas para envio de email', e, s);
      return Response.forbidden(
        jsonEncode({
          'message':
              'Houve um erro inesperado ao tentar enviar seu e-mail de recuperação',
        }),
      );
    }
  }

  @Route.put('/validate-recover-password-code')
  Future<Response> validateRecoverCodeToLogin(Request request) async {
    try {
      var dataRequest = await request.readAsString();

      var dataViewModel = ValidateFourDigitCodeViewModel(dataRequest);

      await userService.validateRecoveryPasswordFourDigitCode(
        dataViewModel.email,
        dataViewModel.code,
      );

      return Response.ok(
        jsonEncode({'message': 'Código validado com sucesso!'}),
      );
    } on InvalidRecover4digitCodeException catch (e, s) {
      log.error('O código inserido é inválido.', e, s);
      return Response.forbidden(
        jsonEncode({'message': 'Código de recuperação incorreto.'}),
      );
    } on DatabaseException catch (e, s) {
      log.error(
        'Erro ao validar o seu código, por favor, tente novamente em alguns instantes.',
        e,
        s,
      );
      return Response.forbidden(
        jsonEncode({
          'message':
              'Houve um erro de conexão com o servidor, tente novamente em alguns instantes.',
        }),
      );
    } on UserNotFoundException catch (e, s) {
      log.error(
        'Não foi encontrado nenhum usuário com o e-mail inserido.',
        e,
        s,
      );
      return Response.notFound(
        jsonEncode({
          'message': 'Não foi encontrado nenhum usuário com o e-mail inserido.',
        }),
      );
    }
  }

  @Route.put('/change-password')
  Future<Response> changeUserPassword(Request request) async {
    try {
      var data = await request.readAsString();
      // log.info('Data Received - AuthContorller: $data');

      var viewModel = ChangePasswordViewModel(data);

      await userService.changeUserPassword(viewModel.email, viewModel.newPass);

      return Response.ok(
        jsonEncode({'message': 'Senha alterada com sucesso!'}),
      );
    } on InvalidNewPasswordException catch (e, s) {
      log.error('A senha inserida é inválida', e, s);
      return Response.forbidden(jsonEncode({'message': e.message}));
    } on DatabaseException catch (e, s) {
      log.error('DatabaseException', e, s);
      return Response.forbidden(jsonEncode({'message': e}));
    }
  }

  Router get router => _$AuthControllerRouter(this);
}
