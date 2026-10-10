class AppConfig {
  /// Client ID OAuth di Google (tipo "Applicazione web"). In alternativa si può
  /// inserire dall'area admin → Impostazioni, oppure passarlo in fase di build:
  ///   flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
}
