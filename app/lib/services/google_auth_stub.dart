import 'google_token.dart';

Future<GoogleToken> requestGoogleAccessToken({
  required String clientId,
  required String scope,
  String prompt = '',
}) async {
  throw GoogleAuthException(
    'Il collegamento a Google Calendar è disponibile solo nella versione web.',
  );
}
