// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:dotenv/dotenv.dart';
import 'package:walleto_dart_api/application/helpers/crypt_helper.dart';
import 'package:injectable/injectable.dart';
import 'package:mysql1/mysql1.dart';

import 'package:walleto_dart_api/application/database/i_database_connection.dart';
import 'package:walleto_dart_api/application/exceptions/credentials_not_found_exception.dart';
import 'package:walleto_dart_api/application/exceptions/database_exception.dart';
import 'package:walleto_dart_api/application/exceptions/invalid_recover_4digit_code_exception.dart';
import 'package:walleto_dart_api/application/exceptions/user_exists_exception.dart';
import 'package:walleto_dart_api/application/exceptions/user_not_found_exception.dart';
import 'package:walleto_dart_api/application/helpers/random_hash_coder_helper.dart';
import 'package:walleto_dart_api/entities/enums/custom_platform.dart';
import 'package:walleto_dart_api/entities/user.dart';
import 'package:walleto_dart_api/logger/i_logger.dart';
import 'package:walleto_dart_api/modules/user/repository/i_user_repository.dart';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

@Injectable(as: IUserRepository)
class UserRepository implements IUserRepository {
  final IDatabaseConnection connection;
  final ILogger log;
  UserRepository({required this.connection, required this.log});

  @override
  Future<void> changeUserPassword(String email, String newPassword) async {
    MySqlConnection? conn;
    try {
      conn = await connection.openConnection();

      await conn.query(
        'UPDATE `walleto_dart`.users SET `pass_crypto` = (?) WHERE `email` = (?)',
        [CryptHelper.generateSha256Hash(newPassword), email],
      );
    } on MySqlConnection catch (e, s) {
      log.error(
        'Houve um erro ao alterar a sua senha, por favor, tente novamente em alguns instantes.',
        e,
        s,
      );
      throw DatabaseException(
        message:
            'Houve um erro ao alterar a sua senha, por favor, tente novamente em alguns instantes.',
      );
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<User> createUser(User user) async {
    MySqlConnection? conn;
    try {
      conn = await connection.openConnection();

      await conn.query(
        '''
          INSERT INTO users values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          null,
          user.nomeUsuario,
          user.email,
          user.cpf,
          user.telefone,
          CryptHelper.generateSha256Hash(user.passwordCrypto!),
          '', // Pass recovery token
          user.iosToken,
          user.androidToken,
          user.refreshToken,
          user.recoverToken,
          user.profileImage != null ? user.profileImage!.toList() : null,
          user.dataCriacaoConta?.toUtc(),
        ],
      );

      var myResults = await conn.query('SELECT * FROM users WHERE email = ?', [
        user.email,
      ]);

      if (myResults.isEmpty) {
        throw UserNotFoundException(message: 'User not found after creation');
      }

      final createdUser = myResults.first;
      User newUser = User(
        id: createdUser['id'] as int,
        nomeUsuario: createdUser['nome_user'] as String,
        email: createdUser['email'] as String,
        cpf: createdUser['cpf'] as String,
        telefone: createdUser['telefone'] as String,
        passwordCrypto: createdUser['pass_crypto'] as String,
        iosToken: createdUser['ios_token'] as String?,
        androidToken: createdUser['android_token'] as String?,
        refreshToken: createdUser['refresh_token'] as String?,
        recoverToken: createdUser['recover_token'] as String?,
        // profileImage:
        //     createdUser['profile_image'] != null
        //         ? Uint8List.fromList(createdUser['profile_image'] as List<int>)
        //         : null,
        profileImage:
              createdUser['profile_image'] != null
                  ? Uint8List.fromList(
                    (createdUser['profile_image'] as Blob).toBytes(),
                  )
                  : null,
        dataCriacaoConta: createdUser['data_criacao_conta'],
      );

      return newUser;
    } on MySqlException catch (e, s) {
      if (e.message.contains('users.email_UNIQUE') ||
          e.message.contains('Duplicate entry')) {
        log.error('Usuário já cadastrado na base de dados.', e, s);
        throw UserExistsException();
      }
      log.error('Error creating user', e, s);
      throw DatabaseException(message: 'Erro ao criar usuário.');
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<String> deleteUser(int id, User contaConectada) async {
    MySqlConnection? conn;

    if (contaConectada.id != id) {
      throw UserNotFoundException(
        message: 'Você não tem permissão para deletar esse usuário.',
      );
    }

    try {
      conn = await connection.openConnection();

      await conn.transaction((_innerConn) async {
        await Future.wait([
          _innerConn.query(
            'DELETE FROM `walleto_dart`.user WHERE `email` = (?)',
            [contaConectada.email],
          ),
        ]);
      });

      return 'Usuário deletado com sucesso.';
    } on MySqlException catch (e, s) {
      log.error('Erro ao deletar usuário com ID: $id', e, s);
      throw DatabaseException(message: 'Erro ao deletar usuário.');
    } finally {
      conn?.close();
    }
  }

  @override
  Future<User> findById(int id) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();
      var myResults = await conn.query(
        '''
          SELECT * from `walleto_dart`.users WHERE `id` = (?)
          ''',
        [id],
      );

      if (myResults.isEmpty) {
        log.error('Usuário não encontrado com o ID: $id');
        throw UserNotFoundException(
          message: 'Usuário não encontrado com o ID: $id',
        );
      } else {
        final dataMySql = myResults.first;
        return User(
          id: dataMySql['id'] as int,
          nomeUsuario: dataMySql['nome_user'],
          email: dataMySql['email'],
          cpf: dataMySql['cpf'],
          telefone: dataMySql['telefone'],
          passwordCrypto: dataMySql['pass_crypto'],
          iosToken: dataMySql['ios_token'],
          androidToken: dataMySql['android_token'],
          refreshToken: dataMySql['refresh_token'],
          recoverToken: dataMySql['recover_token'],
          profileImage:
              dataMySql['profile_image'] != null
                  ? Uint8List.fromList(
                    (dataMySql['profile_image'] as Blob).toBytes(),
                  )
                  : null,
          dataCriacaoConta: dataMySql['data_criacao_conta'],
        );
      }
    } on MySqlException catch (e, s) {
      log.error('Erro ao buscar usuário por ID', e, s);
      throw DatabaseException();
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<User> loginWithEmailAndPassword(String email, String password) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      var query = '''
        SELECT * 
        FROM `walleto_dart`.users
         WHERE 
         `email` = (?) AND
         `pass_crypto` = (?)
      ''';

      final myResults = await conn.query(query, [
        email,
        CryptHelper.generateSha256Hash(password),
      ]);

      if (myResults.isEmpty) {
        log.error('Usuário ou senha incorretos.');
        throw UserNotFoundException(message: 'Usuário ou senha inválidos.');
      } else {
        // if (myResults.first['email_confirmed'] == 0) {
        //   throw UserEmailNotYetConfirmedException(
        //       message: 'E-mail ainda não confirmado.');
        // }

        final userSqlData = myResults.first;
        return User(
          id: userSqlData['id'] as int,
          nomeUsuario: userSqlData['nome_user'] as String,
          email: userSqlData['email'] as String,
          cpf: userSqlData['cpf'] as String,
          telefone: userSqlData['telefone'] as String,
          passwordCrypto: userSqlData['pass_crypto'] as String,
          iosToken: userSqlData['ios_token'] as String?,
          androidToken: userSqlData['android_token'] as String?,
          refreshToken: userSqlData['refresh_token'] as String?,
          recoverToken: userSqlData['recover_token'] as String?,
          // profileImage:
          //     userSqlData['profile_image'] != null
          //         ? Uint8List.fromList(
          //           userSqlData['profile_image'] as List<int>,
          //         )
          //         : null,
          profileImage:
              userSqlData['profile_image'] != null
                  ? Uint8List.fromList(
                    (userSqlData['profile_image'] as Blob).toBytes(),
                  )
                  : null,
          dataCriacaoConta: userSqlData['data_criacao_conta'],
        );
      }
    } on MySqlException catch (e, s) {
      log.error('Internal Server Error.', e, s);
      throw DatabaseException(message: e.message);
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> sendRecoveryPasswordEmail(
    String userEmail,
    String random4DigitCode,
  ) async {
    String? admin = env['ADMIN_EMAIL'];
    String adminGmail = '${admin}@gmail.com';
    String? code = env['SMTP_SERVER_CODE'];
    MySqlConnection? conn;

    if (admin == null || code == null) {
      throw CredentialsNotFoundException(
        message: 'Erro ao encontrar as credenciais para enviar o e-mail.',
      );
    }
    try {
      conn = await connection.openConnection();

      var myResults = await conn.query(
        'SELECT * FROM `walleto_dart`.users WHERE `email` = (?)',
        [userEmail],
      );

      if (myResults.isEmpty) {
        throw UserNotFoundException(
          message: 'Nenhum usuário encontrado com esse E-mail em nosso sistema',
        );
      }

      final smtpServer = gmail(adminGmail, code);

      final message =
          Message()
            ..from = Address(adminGmail, 'Thiago Abreu')
            ..recipients.add('$userEmail')
            ..subject = 'Recuperação de Senha'
            ..html = '''
        <h2>Olá</h2>
        <p>Utilize o código abaixo para recuperar a sua senha no aplicativo Walleto referente a conta do seu email</p>
        <p style="font-size: 18px;">Código: <strong style="color: rgb(23, 30, 56); font-size: 24px;">$random4DigitCode</strong></p>
        <p>Se você não solicitou a redefinição da sua senha, ignore este e-mail.</p>
        <p>Obrigado,</p>
        <p>Equipe de Desenvolvimento da Walleto.</p>
        ''';

      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      log.error(e);
      rethrow;
    } on CredentialsNotFoundException catch (e) {
      log.error(e);
      rethrow;
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> updateDeviceToken(
    int id,
    String token,
    CustomPlatform platform,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      var set = '';
      if (platform == CustomPlatform.ios) {
        set = 'ios_token = (?)';
      } else {
        set = 'android_token = (?)';
      }

      final query = '''
        UPDATE `walleto_dart`.users SET $set WHERE `id` = (?)
      ''';

      await conn.query(query, [token, id]);
    } on MySqlException catch (e, s) {
      log.error('Houve um erro ao atualizar Device Token do usuário.', e, s);
      throw DatabaseException();
    } finally {
      conn?.close();
    }
  }

  @override
  Future<void> updateProfileImage(User user, Uint8List data) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();
      final query = '''
        UPDATE `walleto_dart`.users 
        SET `profile_image` = (?)
        WHERE `id` = (?)
      ''';
      await conn.query(query, [data, user.id]);
    } on MySqlException catch (e, s) {
      log.error('Erro ao atualizar a imagem de perfil do usuário.', e, s);
      throw DatabaseException(message: 'Erro ao atualizar a imagem de perfil.');
    } finally {
      conn?.close();
    }
  }

  @override
  Future<void> updateRecoverTokenOnDatabase(
    String userEmail,
    String random4DigitCode,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      var resultUser = await conn.query(
        'SELECT * FROM `walleto_dart`.users WHERE `email` = (?)',
        [userEmail],
      );
      if (resultUser.isEmpty) {
        throw UserNotFoundException(
          message: 'Usuário não encontrado com esse e-mail.',
        );
      }
      await conn.query(
        'UPDATE `walleto_dart`.users SET `pass_recovery_token` = (?) WHERE `email` = (?)',
        [random4DigitCode, userEmail],
      );
    } on MySqlConnection catch (e, s) {
      log.error('Erro ao atualizar token de recuperação de senha', e, s);
      throw DatabaseException(
        message:
            'Houve um erro ao atualizar o seu token de recuperação, tente novamnete em alguns instantes',
      );
    } on UserNotFoundException catch (e, s) {
      log.error('Usuário não encontrado com esse e-mail no sistema.', e, s);
      rethrow;
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> updateRefreshToken(User user) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();
      await conn.query(
        'UPDATE `walleto_dart`.users SET refresh_token = (?) WHERE `id` = (?)',
        [user.refreshToken!, user.id!],
      );
    } on MySqlException catch (e, s) {
      log.error('Erro ao confirmar o Login.', e, s);
      throw DatabaseException(
        message: 'Erro ao atualizar Refresh Token',
        exception: e,
      );
    } finally {
      conn?.close();
    }
  }

  @override
  Future<void> updateUserDeviceTokenAndRefreshToken(User user) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();
      final setParams = <String, dynamic>{};
      if (user.iosToken != null) {
        setParams.putIfAbsent('ios_token', () => user.iosToken);
      } else {
        setParams.putIfAbsent('android_token', () => user.androidToken);
      }

      final query = '''
        UPDATE `walleto_dart`.users
        SET ${setParams.keys.elementAt(0)} = (?),
         refresh_token = (?)
        WHERE 
        id = ?
      ''';

      await conn.query(query, [
        setParams.values.elementAt(0),
        user.refreshToken,
        user.id,
      ]);
    } on MySqlException catch (e, s) {
      log.error('Erro ao confirmar o Login.', e, s);
      throw DatabaseException(
        message:
            'Erro ao se conectar com o banco de dados para confirmar o Login.',
        exception: e,
      );
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> validateRecoveryPasswordFourDigitCode(
    String email,
    String code,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      var checkIfUserExists = await conn.query(
        'SELECT * FROM `walleto_dart`.users WHERE `email` = (?)',
        [email],
      );

      if (checkIfUserExists.isEmpty) {
        throw UserNotFoundException(
          message: 'Não foi encontrado nenhum usuário com esse e-mail.',
        );
      }

      var compareCodes = await conn.query(
        'SELECT * FROM `walleto_dart`.users WHERE `email` = (?) AND `pass_recovery_token` = (?)',
        [email, code],
      );

      if (compareCodes.isEmpty) {
        throw InvalidRecover4digitCodeException(
          message: 'Código de recuperação incorreto',
        );
      }
      //! At this moment, the code is completely validated and the textField with the new password should be already available.
      //! For this reason I'm creating a new code, this time with 5 digits, so my user will need to request a new code
      //! if he's going to change his password again or in case he leaves the application without changing his password.
      var newRandom5DigitRecoveryCode =
          RandomHashCoderHelper.getRandomNumericString(5);

      await conn.query(
        '''
         UPDATE `walleto_dart`.users SET `pass_recovery_token` = (?) WHERE `email` = (?)
        ''',
        [newRandom5DigitRecoveryCode, email],
      );
    } on MySqlException catch (e, s) {
      log.error(
        'Houve um erro ao validar o código, por favor, tente novamente em alguns instantes.',
        e,
        s,
      );
      throw DatabaseException(
        message:
            'Houve um erro ao validar o código, por favor, tente novamente em alguns instantes.',
      );
    } on UserNotFoundException catch (e, s) {
      log.error('Não foi encontrado nenhum usuário com esse e-mail.', e, s);
      rethrow;
    } on DatabaseException {
      rethrow;
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> updateValidateEmailCodeOnDatabase(
    String userEmail,
    String random4DigitCode,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      var resultUser = await conn.query(
        'SELECT * FROM `walleto_dart`.users WHERE `email` = (?)',
        [userEmail],
      );
      if (resultUser.isEmpty) {
        throw UserNotFoundException(
          message: 'Usuário não encontrado com esse e-mail.',
        );
      }
      await conn.query(
        'UPDATE `walleto_dart`.users SET `token_email_confirm` = (?) WHERE `email` = (?)',
        [random4DigitCode, userEmail],
      );
    } on MySqlConnection catch (e, s) {
      log.error('Erro ao atualizar token de confirmação de conta.', e, s);
      throw DatabaseException(
        message:
            'Houve um erro ao atualizar o seu token de confirmação de conta, tente novamnete em alguns instantes',
      );
    } on UserNotFoundException catch (e, s) {
      log.error('Usuário não encontrado com esse e-mail no sistema.', e, s);
      rethrow;
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> validateConfirmEmailFourDigitCode(
    String email,
    String code,
  ) async {
    MySqlConnection? conn;

    try {
      conn = await connection.openConnection();

      var checkIfUserExists = await conn.query(
        'SELECT * FROM `walleto_dart`.users WHERE `email` = (?)',
        [email],
      );

      if (checkIfUserExists.isEmpty) {
        throw UserNotFoundException(
          message: 'Não foi encontrado nenhum usuário com esse e-mail.',
        );
      }

      var compareCodes = await conn.query(
        'SELECT * FROM `walleto_dart`.users WHERE `email` = (?) AND `token_email_confirm` = (?)',
        [email, code],
      );

      if (compareCodes.isEmpty) {
        throw InvalidRecover4digitCodeException(
          message: 'Código de validação incorreto',
        );
      }
      //! At this moment, the code is completely validated and the textField with the new password should be already available.
      //! For this reason I'm creating a new code, this time with 5 digits, so my user will need to request a new code
      //! if he's going to change his password again or in case he leaves the application without changing his password.
      var newRandom5DigitRecoveryCode =
          RandomHashCoderHelper.getRandomNumericString(5);

      await conn.query(
        '''
          UPDATE `walleto_dart`.users SET `token_email_confirm` = (?), `email_confirmed` = (?) WHERE `email` = (?)
        ''',
        [newRandom5DigitRecoveryCode, true, email],
      );
    } on MySqlException catch (e, s) {
      log.error(
        'Houve um erro ao validar o código, por favor, tente novamente em alguns instantes.',
        e,
        s,
      );
      throw DatabaseException(
        message:
            'Houve um erro ao validar o código, por favor, tente novamente em alguns instantes.',
      );
    } on UserNotFoundException catch (e, s) {
      log.error('Não foi encontrado nenhum usuário com esse e-mail.', e, s);
      rethrow;
    } on DatabaseException {
      rethrow;
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> sendValidateEmailCode(
    String userEmail,
    String random4DigitCode,
  ) async {
    String? admin = env['ADMIN_EMAIL'];
    String adminGmail = '${admin}@gmail.com';
    String? code = env['SMTP_SERVER_CODE'];

    if (admin == null || code == null) {
      throw CredentialsNotFoundException(
        message: 'Erro ao encontrar as credenciais para enviar o e-mail.',
      );
    }
    try {
      final smtpServer = gmail(adminGmail, code);

      final message =
          Message()
            ..from = Address(adminGmail, 'ConstruDesk')
            ..recipients.add('$userEmail')
            ..subject = 'ConstruDesk - Validar Email'
            ..html = '''
        <h2>Olá</h2>
        <p> Digite no aplicativo Walleto o seguinte código para validar sua conta e terminar seu cadastro: </p>
        <p style="font-size: 18px;">Código: <strong style="color: rgb(23, 30, 56); font-size: 24px;">$random4DigitCode</strong></p>
        <p>Se você não solicitou a redefinição da sua senha, ignore este e-mail.</p>
        <p>Obrigado,</p>
        <p>Equipe de Desenvolvimento da Walleto.</p>
        <img src="https://walleto-prod.s3.us-east-2.amazonaws.com/uploads/walleto_fundo_azul.jpg">
        ''';

      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      log.error(e);
      rethrow;
    } on CredentialsNotFoundException catch (e) {
      log.error(e);
      rethrow;
    }
  }
}
