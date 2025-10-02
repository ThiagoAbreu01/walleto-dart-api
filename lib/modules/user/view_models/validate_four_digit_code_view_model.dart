import 'package:walleto_dart_api/application/helpers/request_mapping.dart';

class ValidateFourDigitCodeViewModel extends RequestMapping {
  late String email;
  late String code;

  ValidateFourDigitCodeViewModel(String dataRequest) : super(dataRequest);

  @override
  void map() {
    email = data['email'];
    code = data['code'];
  }
}
