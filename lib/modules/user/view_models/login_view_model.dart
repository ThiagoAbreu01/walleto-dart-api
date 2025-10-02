import 'package:walleto_dart_api/application/helpers/request_mapping.dart';

class LoginViewModel extends RequestMapping {
  late String email;
  late String password;
  late bool socialLogin;
  late String imageUrl;
  late String socialType;
  late String socialKey;

  LoginViewModel(String dataRequest) : super(dataRequest);

  @override
  void map() {
    email = data['email'];
    password = data['social_login'] ? '' : data['pass_crypto'];
    socialLogin = data['social_login'];
    imageUrl = data['image_url'] ?? '';
    socialType = data['social_login'] ? data['social_type'] : 'APP';
    socialKey = data['social_key'] ?? '';
  }
}
