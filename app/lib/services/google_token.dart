/// Token OAuth restituito da Google Identity Services.
class GoogleToken {
  GoogleToken(this.accessToken, this.expiresAt);
  final String accessToken;
  final DateTime expiresAt;

  bool get isValid =>
      DateTime.now().isBefore(expiresAt.subtract(const Duration(minutes: 1)));
}

class GoogleAuthException implements Exception {
  GoogleAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
