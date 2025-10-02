import 'package:walleto_dart_api/application/helpers/request_mapping.dart';

class RecoverPasswordViewModel extends RequestMapping {
  late String email;
  RecoverPasswordViewModel(String dataRequest) : super(dataRequest);

  @override
  void map() {
    email = data['email'];
  }
}
