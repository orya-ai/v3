/// Constants for application routes
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();
  
  // Auth routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  
  // Main routes
  static const String root = '/';
  static const String dashboard = '/dashboard';
  static const String activities = '/activities';
  static const String conversationCards = '/conversation-cards';
  static const String profile = '/profile';
  
  // Profile routes
  static const String settings = '/settings';
  static const String editProfile = '/profile/edit';
  static const String privacyPolicy = '/profile/privacy-policy';
  static const String terms = '/profile/terms';
  
  // Other routes
  static const String notifications = '/notifications';
  static const String search = '/search';
  
  // Error routes
  static const String notFound = '/404';
}
