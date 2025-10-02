import 'package:walleto_dart_api/application/helpers/request_mapping.dart';

class ChangePasswordViewModel extends RequestMapping {
  late String email;
  late String newPass;

  ChangePasswordViewModel(String dataRequest) : super(dataRequest);

  @override
  void map() {
    email = data['email'];
    newPass = data['password'];
  }
}
