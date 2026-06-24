class RouteNames {
  // Onboarding
  static const String onboarding = '/onboarding';
  static const String campusSelection = '/campus-selection';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Buyer (COD only)
  static const String home = '/home';
  static const String cart = '/cart';
  static const String notification = '/notification';
  static const String profile = '/profile';
  static const String productDetail = '/product/:id';
  static const String orderHistory = '/order-history';
  static const String orderDetail = '/order/:id';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminSellers = '/admin/sellers';
  static const String sellerRegistration = '/admin/sellers/register';
  static const String adminTransactions = '/admin/transactions';
  static const String adminCampuses = '/admin/campuses';
  static const String sellerManagement = '/admin/sellers';
  static const String categoryManagement = '/admin/categories';

  // Seller
  static const String sellerDashboard = '/seller';
  static const String sellerMenu = '/seller/menu';
  static const String sellerOrders = '/seller/orders';
  static const String sellerChat = '/seller/orders/:orderId/chat';
  static const String sellerProfile = '/seller/profile';
}
