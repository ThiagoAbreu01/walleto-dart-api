import 'package:walleto_dart_api/application/helpers/request_mapping.dart';

class UserConfirmInputModel extends RequestMapping {
  int userID;
  String accessToken;
  late String? iosDeviceToken;
  late String? androidDeviceToken;
  UserConfirmInputModel({
    required this.userID,
    required this.accessToken,
    required String data,
  }) : super(data);

  @override
  void map() {
    iosDeviceToken = data['ios_token'];
    androidDeviceToken = data['android_token'];
  }
}
