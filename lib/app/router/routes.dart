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
  static const String social = '/social';
  static const String activities = '/activities';
  static const String conversationCards = '/conversation-cards';
  static const String discovery = '/discovery';
  
  // Profile routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String editProfile = '/profile/edit';
  
  // Other routes
  static const String notifications = '/notifications';
  static const String search = '/search';
  
  // Error routes
  static const String notFound = '/404';
}
