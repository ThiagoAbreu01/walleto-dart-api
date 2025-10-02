import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:dotenv/dotenv.dart';

class JwtHelper {
  JwtHelper._();

  static String generateJWT(int userID) {
    final claimSet = JwtClaim(
      issuer: 'construdesk',
      subject: userID.toString(),
      expiry: DateTime.now().add(const Duration(days: 1)),
      notBefore: DateTime.now(),
      issuedAt: DateTime.now(),
      otherClaims: <String, dynamic>{},
      maxAge: const Duration(days: 1),
    );

    return 'Bearer ${issueJwtHS256(claimSet, _jwtSecret)}';
  }

  static final String _jwtSecret = env['JWT_SECRET'] ?? env['jwtSecret']!;

  static JwtClaim getClaims(String token) {
    return verifyJwtHS256Signature(token, _jwtSecret);
  }

  static String refreshToken(String accessToken) {
    final claimSet = JwtClaim(
      issuer: accessToken,
      subject: 'RefreshToken',
      expiry: DateTime.now().add(const Duration(days: 20)),
      //! Evitando possíveis fraudes e etc., já que o access token está válido por 1 dia (linha abaixo)
      notBefore: DateTime.now().add(const Duration(hours: 12)),      issuedAt: DateTime.now(),
      otherClaims: <String, dynamic>{},
      maxAge: const Duration(days: 2),
    );
    return 'Bearer ${issueJwtHS256(claimSet, _jwtSecret)}';
  }
}
