import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/auth_storage.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/phone_input_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/property_details/presentation/screens/property_details_screen.dart';
import '../../features/project_details/presentation/screens/project_details_screen.dart';
import '../../features/rental_details/presentation/screens/rental_details_screen.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/my_listings/presentation/screens/my_listings_screen.dart';
import '../../features/add_listing/presentation/screens/add_listing_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/chat/presentation/screens/chats_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../constants/app_constants.dart';

Page<dynamic> _page(GoRouterState state, Widget child) {
  if (Platform.isIOS) {
    return CupertinoPage(key: state.pageKey, child: child);
  }
  return MaterialPage(key: state.pageKey, child: child);
}

// Routes that do not require authentication
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.phoneInput,
  AppRoutes.otp,
  AppRoutes.register,
};

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  redirect: (context, state) async {
    final location = state.matchedLocation;
    final isPublic = _publicRoutes.any((r) => location.startsWith(r));
    if (isPublic) return null; // always allow auth screens
    final loggedIn = await AuthStorage.isLoggedIn();
    if (!loggedIn) return AppRoutes.login;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => _page(state, const SplashScreen()),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) => _page(state, const OnboardingScreen()),
    ),
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => _page(state, const LoginScreen()),
      routes: [
        GoRoute(
          path: 'phone',
          pageBuilder: (context, state) => _page(state, const PhoneInputScreen()),
        ),
        GoRoute(
          path: 'otp',
          pageBuilder: (context, state) => _page(state, const OtpScreen()),
        ),
        GoRoute(
          path: 'register',
          pageBuilder: (context, state) => _page(state, const RegisterScreen()),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => _page(state, const HomeScreen()),
    ),
    GoRoute(
      path: '/property/:id',
      pageBuilder: (context, state) => _page(
        state,
        PropertyDetailsScreen(listingId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/project/:id',
      pageBuilder: (context, state) => _page(
        state,
        ProjectDetailsScreen(projectId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/rental/:id',
      pageBuilder: (context, state) => _page(
        state,
        RentalDetailsScreen(rentalId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: AppRoutes.search,
      pageBuilder: (context, state) => _page(state, const SearchScreen()),
    ),
    GoRoute(
      path: AppRoutes.addListing,
      pageBuilder: (context, state) => _page(state, const AddListingScreen()),
    ),
    GoRoute(
      path: AppRoutes.account,
      pageBuilder: (context, state) => _page(state, const AccountScreen()),
    ),
    GoRoute(
      path: AppRoutes.myListings,
      pageBuilder: (context, state) => _page(state, const MyListingsScreen()),
    ),
    GoRoute(
      path: AppRoutes.chat,
      pageBuilder: (context, state) => _page(state, const ChatsScreen()),
    ),
    GoRoute(
      path: AppRoutes.chatDetail,
      pageBuilder: (context, state) => _page(
        state,
        ChatDetailScreen(chatId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      pageBuilder: (context, state) => _page(state, const NotificationsScreen()),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      pageBuilder: (context, state) => _page(state, const FavoritesScreen()),
    ),
    GoRoute(
      path: AppRoutes.wallet,
      pageBuilder: (context, state) => _page(state, const WalletScreen()),
    ),
    GoRoute(
      path: '/profile/:id',
      pageBuilder: (context, state) => _page(
        state,
        ProfileScreen(profileId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => _page(state, const SettingsScreen()),
    ),
  ],
);
