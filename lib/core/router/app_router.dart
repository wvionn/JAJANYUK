import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/campus_selection_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/notification/presentation/pages/notification_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_sellers_page.dart';
import '../../features/admin/presentation/pages/admin_transactions_page.dart';
import '../../features/admin/presentation/pages/admin_campuses_page.dart';
import '../../features/admin/presentation/pages/seller_registration_page.dart';
import '../../features/seller/presentation/pages/seller_dashboard_page.dart';
import '../../features/seller/presentation/pages/seller_menu_page.dart';
import '../../features/seller/presentation/pages/seller_orders_page.dart';
import '../../features/seller/presentation/pages/seller_chat_page.dart';
import '../../features/seller/presentation/pages/seller_profile_page.dart';
import '../../features/seller/presentation/pages/seller_reports_page.dart';
import '../widgets/main_shell.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.onboarding,
    routes: [
      // Onboarding Routes
      GoRoute(
        path: RouteNames.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.campusSelection,
        name: RouteNames.campusSelection,
        builder: (context, state) => const CampusSelectionPage(),
      ),

      // Auth Routes
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // Buyer Routes with Shell Navigation (COD only)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: RouteNames.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: RouteNames.cart,
            name: RouteNames.cart,
            builder: (context, state) => const CartPage(),
          ),
          GoRoute(
            path: RouteNames.notification,
            name: RouteNames.notification,
            builder: (context, state) => const NotificationPage(),
          ),
          GoRoute(
            path: RouteNames.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // Admin Routes
      GoRoute(
        path: RouteNames.adminDashboard,
        name: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: RouteNames.adminUsers,
        name: RouteNames.adminUsers,
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: RouteNames.adminSellers,
        name: RouteNames.adminSellers,
        builder: (context, state) => const AdminSellersPage(),
      ),
      GoRoute(
        path: RouteNames.sellerRegistration,
        name: RouteNames.sellerRegistration,
        builder: (context, state) => const SellerRegistrationPage(),
      ),
      GoRoute(
        path: RouteNames.adminTransactions,
        name: RouteNames.adminTransactions,
        builder: (context, state) => const AdminTransactionsPage(),
      ),
      GoRoute(
        path: RouteNames.adminCampuses,
        name: RouteNames.adminCampuses,
        builder: (context, state) => const AdminCampusesPage(),
      ),

      // Seller Routes
      GoRoute(
        path: RouteNames.sellerDashboard,
        name: RouteNames.sellerDashboard,
        builder: (context, state) => const SellerDashboardPage(),
      ),
      GoRoute(
        path: RouteNames.sellerMenu,
        name: RouteNames.sellerMenu,
        builder: (context, state) => const SellerMenuPage(),
      ),
      GoRoute(
        path: RouteNames.sellerOrders,
        name: RouteNames.sellerOrders,
        builder: (context, state) => const SellerOrdersPage(),
      ),
      GoRoute(
        path: RouteNames.sellerChat,
        name: RouteNames.sellerChat,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return SellerChatPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: RouteNames.sellerProfile,
        name: RouteNames.sellerProfile,
        builder: (context, state) => const SellerProfilePage(),
      ),
      GoRoute(
        path: RouteNames.sellerReports,
        name: RouteNames.sellerReports,
        builder: (context, state) => const SellerReportsPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
