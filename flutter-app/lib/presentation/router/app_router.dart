import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/presentation/providers/auth_provider.dart';
import 'package:medcin_app/presentation/screens/chat/conversations_screen.dart';
import 'package:medcin_app/presentation/screens/children/child_profile_screen.dart';
import 'package:medcin_app/presentation/screens/doctor/doctor_home_screen.dart';
import 'package:medcin_app/presentation/screens/forgot_password_screen.dart';
import 'package:medcin_app/presentation/screens/email_verification_screen.dart';
import 'package:medcin_app/presentation/screens/home_screen.dart';
import 'package:medcin_app/presentation/screens/login_screen.dart';
import 'package:medcin_app/presentation/screens/main_shell.dart';
import 'package:medcin_app/presentation/screens/notifications_screen.dart';
import 'package:medcin_app/presentation/screens/privacy_policy_screen.dart';
import 'package:medcin_app/presentation/screens/profile_screen.dart';
import 'package:medcin_app/presentation/screens/register_screen.dart';
import 'package:medcin_app/presentation/screens/splash_screen.dart';
import 'package:medcin_app/presentation/screens/subscription_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: AuthProvider.instance,
  redirect: (context, state) {
    final auth = AuthProvider.instance;
    final status = auth.status;
    final loc = state.matchedLocation;
    final onSplash = loc == '/splash';
    final inAuth = loc.startsWith('/auth');

    if (status == AuthStatus.unknown || status == AuthStatus.checking) {
      return onSplash ? null : '/splash';
    }

    if (status == AuthStatus.authenticated) {
      if (onSplash || inAuth) {
        return auth.isDoctor ? '/doctor-home' : '/';
      }
      return null;
    }

    if (inAuth) return null;
    if (loc == '/privacy') return null;
    return '/auth/login';
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) =>
          EmailVerificationScreen(email: state.uri.queryParameters['email'] ?? ''),
    ),
    GoRoute(
      path: '/auth',
      redirect: (context, state) => state.uri.path == '/auth' ? '/auth/login' : null,
      routes: [
        GoRoute(
          path: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/children',
              builder: (context, state) => const ChildProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/subscription',
              builder: (context, state) => const SubscriptionScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/messages',
              builder: (context, state) => const ConversationsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/doctor-home',
      builder: (context, state) => const DoctorHomeScreen(),
    ),
  ],
);