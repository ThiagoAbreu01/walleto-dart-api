// ignore_for_file: public_member_api_docs, sort_constructors_first
class WrongColumnCountException implements Exception {
  final String? message;
  WrongColumnCountException({
    this.message,
  });
}
