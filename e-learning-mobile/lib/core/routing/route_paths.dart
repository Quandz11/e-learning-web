class RoutePaths {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const courses = '/courses';
  static const courseDetail = '/courses/:id';
  static const myCourses = '/profile/my-courses';
  static const checkout = '/checkout';
  static const orders = '/profile/orders';
  static const paymentResult = '/payment-result';
  static const forum = '/forum';
  static const referral = '/profile/referral';
  static const wellnessAi = '/wellness-ai';
  static const chatNotification = '/profile/chat-notification';
  static const profile = '/profile';
  static const learningPlayer = '/learning-player/:id';

  static String courseDetailPath(String id) => '/courses/$id';
  static String learningPlayerPath(String id) => '/learning-player/$id';
}
