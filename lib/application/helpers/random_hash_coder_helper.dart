import 'dart:math';

class RandomHashCoderHelper {
  RandomHashCoderHelper._();

  static final _allChars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final _allnumeric = '0123456789';
  static final Random _rnd = Random.secure();
  //! Default Length para HashID de obra = 25.
  static String getRandomAllCharString(int length) =>
      String.fromCharCodes(Iterable.generate(
          length, (_) => _allChars.codeUnitAt(_rnd.nextInt(_allChars.length))));

  //! Usado principalmente para o recover password.
  static String getRandomNumericString(int length) =>
      String.fromCharCodes(Iterable.generate(length,
          (_) => _allnumeric.codeUnitAt(_rnd.nextInt(_allnumeric.length))));
}
