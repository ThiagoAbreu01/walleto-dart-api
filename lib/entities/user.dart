// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

import 'package:mysql1/mysql1.dart';

class User {
  final int? id;
  final String? nomeUsuario;
  final String? email;
  final String? cpf;
  final String? telefone;
  String? passwordCrypto;
  String? iosToken;
  String? androidToken;
  String? refreshToken;
  String? recoverToken;
  Uint8List? profileImage;
  DateTime? dataCriacaoConta;
  User({
    this.id,
    this.nomeUsuario,
    this.email,
    this.cpf,
    this.telefone,
    this.passwordCrypto,
    this.iosToken,
    this.androidToken,
    this.refreshToken,
    this.recoverToken,
    this.profileImage,
    this.dataCriacaoConta,
  });

  User copyWith({
    int? id,
    String? nomeUsuario,
    String? email,
    String? cpf,
    String? telefone,
    String? passwordCrypto,
    String? iosToken,
    String? androidToken,
    String? refreshToken,
    String? recoverToken,
    Uint8List? profileImage,
    DateTime? dataCriacaoConta,
  }) {
    return User(
      id: id ?? this.id,
      nomeUsuario: nomeUsuario ?? this.nomeUsuario,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      telefone: telefone ?? this.telefone,
      passwordCrypto: passwordCrypto ?? this.passwordCrypto,
      iosToken: iosToken ?? this.iosToken,
      androidToken: androidToken ?? this.androidToken,
      refreshToken: refreshToken ?? this.refreshToken,
      recoverToken: recoverToken ?? this.recoverToken,
      profileImage: profileImage ?? this.profileImage,
      dataCriacaoConta: dataCriacaoConta ?? this.dataCriacaoConta,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nome_usuario': nomeUsuario,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
      'pass_crypto': passwordCrypto,
      'ios_token': iosToken,
      'android_token': androidToken,
      'refresh_token': refreshToken,
      'recover_token': recoverToken,
      'profile_image':
          (profileImage != null) == true
              ? base64Encode(profileImage!)
              : null,
      'data_criacao_conta': dataCriacaoConta?.toUtc().toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      nomeUsuario: map['nome_usuario'] as String,
      email: map['email'] as String,
      cpf: map['cpf'] as String,
      telefone: map['telefone'] as String,
      passwordCrypto: map['pass_crypto'] as String,
      iosToken: map['ios_token'] != null ? map['ios_token'] as String : null,
      androidToken:
          map['android_token'] != null ? map['android_token'] as String : null,
      refreshToken:
          map['refresh_token'] != null ? map['refresh_token'] as String : null,
      recoverToken:
          map['recover_token'] != null ? map['recover_token'] as String : null,
      // profileImage:
      //     map['profile_image'] != null
      //         ? Uint8List.fromList(map['profile_image'] as List<int>)
      //         : null,
      profileImage:
          map['profile_image'] != null
              ? Uint8List.fromList(
                    (map['profile_image'] as Blob).toBytes(),
              )
              : null,
      dataCriacaoConta: DateTime.parse(map['data_criacao_conta']),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);
}
