// ignore_for_file: public_member_api_docs, sort_constructors_first

class InvalidNewPasswordException implements Exception {
  final String? message;
  InvalidNewPasswordException({
    this.message,
  });
}
