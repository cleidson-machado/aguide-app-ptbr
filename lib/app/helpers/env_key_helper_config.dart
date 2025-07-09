import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvKeyHelperConfig {

  // Environment Info
  static String get label => dotenv.env['LABEL'] ?? 'UNKNOWN';
  static String get buildFlavor => dotenv.env['BUILD_FLAVOR'] ?? 'development';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0+1';

  // API Base URLs
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get loginUrl => dotenv.env['LOGIN_URL'] ?? '';
  static String get translateUrl => dotenv.env['TRANSLATE_URL'] ?? '';
  static String get chatbotUrl => dotenv.env['CHATBOT_URL'] ?? '';
  static String get imageMocTemp1 => dotenv.env['IMAGES_TEMP_GENERATOR'] ?? '';
  static String get mocApi1 => dotenv.env['MOC_API_A'] ?? '';
  static String get mocApi2 => dotenv.env['MOC_API_B'] ?? '';

  // Auth / Security
  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  static int get tokenExpirationMinutes => int.tryParse(dotenv.env['TOKEN_EXPIRATION_MINUTES'] ?? '') ?? 60;

  // Firebase / Analytics
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // Feature Toggles
  static bool get featureChat => dotenv.env['FEATURE_CHAT'] == 'true';
  static bool get featureBetaUi => dotenv.env['FEATURE_BETA_UI'] == 'true';
  static bool get featureAnalytics => dotenv.env['FEATURE_ANALYTICS'] == 'true';

  // Debug Options
  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'info';
  static bool get mockMode => dotenv.env['MOCK_MODE'] == 'true';

  // Third-Party Services
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';
  static String get stripePublicKey => dotenv.env['STRIPE_PUBLIC_KEY'] ?? '';
  static String get mapboxApiKey => dotenv.env['MAPBOX_API_KEY'] ?? '';
}
