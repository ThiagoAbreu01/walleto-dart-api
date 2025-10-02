
import 'package:walleto_dart_api/application/helpers/request_mapping.dart';

class RegisterUserInputModel extends RequestMapping {
  late String nome;
  late String email;
  late String cpf;
  late String telefone;
  late String password;
  late String confirmPassword;

  RegisterUserInputModel(String dataRequest) : super(dataRequest);

  @override
  void map() {
    nome = data['nome'] as String;
    email = data['email'] as String;
    cpf = data['cpf'] as String;
    telefone = data['telefone'] as String;
    password = data['password'] as String;
    confirmPassword = data['confirm_password'] as String;
  }
}
