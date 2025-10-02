import 'package:walleto_dart_api/application/helpers/request_mapping.dart';

class UserRefreshTokenInputModel extends RequestMapping {
  int userID;
  String accessToken;
  late String refreshToken;
  UserRefreshTokenInputModel({
    required this.userID,
    required this.accessToken,
    required String dataRequest,
  }) : super(dataRequest);

  @override
  void map() {
    refreshToken = data['refresh_token'];
  }
}
