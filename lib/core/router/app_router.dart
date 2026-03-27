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
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
      routes: [
        GoRoute(
          path: 'phone',       // full path: /login/phone
          builder: (context, state) => const PhoneInputScreen(),
        ),
        GoRoute(
          path: 'otp',         // full path: /login/otp
          builder: (context, state) => const OtpScreen(),
        ),
        GoRoute(
          path: 'register',    // full path: /login/register
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/property/:id',
      builder: (context, state) => PropertyDetailsScreen(
        listingId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/rental/:id',
      builder: (context, state) => RentalDetailsScreen(
        rentalId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.addListing,
      builder: (context, state) => const AddListingScreen(),
    ),
    GoRoute(
      path: AppRoutes.account,
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: AppRoutes.myListings,
      builder: (context, state) => const MyListingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) => const ChatsScreen(),
    ),
    GoRoute(
      path: AppRoutes.chatDetail,
      builder: (context, state) => ChatDetailScreen(
        chatId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: AppRoutes.wallet,
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/profile/:id',
      builder: (context, state) => ProfileScreen(
        profileId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
