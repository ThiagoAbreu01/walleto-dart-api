// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException({
    required this.message,
  });
}
