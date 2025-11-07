import 'package:go_router/go_router.dart';
import 'package:puntocheck/presentation/controllers/auth_controller.dart';
import 'package:puntocheck/presentation/pages/auth/forgot_password_code_page.dart';
import 'package:puntocheck/presentation/pages/auth/forgot_password_email_page.dart';
import 'package:puntocheck/presentation/pages/auth/login_page.dart';
import 'package:puntocheck/presentation/pages/auth/register_page.dart';
import 'package:puntocheck/presentation/pages/auth/reset_password_page.dart';
import 'package:puntocheck/presentation/pages/home/home_page.dart';

class AppRouter {
  AppRouter(this._authController);

  final AuthController _authController;

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _authController,
    redirect: (context, state) {
      final loggedIn = _authController.currentUser != null;
      final location = state.uri.path;
      final goingToAuth = <String>{'/login', '/register', '/forgot-email', '/forgot-code', '/reset-password'}
          .contains(location);
      if (!loggedIn && location == '/home') {
        return '/login';
      }
      if (loggedIn && goingToAuth) {
        return '/home';
      }
      return null;
    },
    routes: <GoRoute>[
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(path: '/forgot-email', builder: (context, state) => const ForgotPasswordEmailPage()),
      GoRoute(path: '/forgot-code', builder: (context, state) => const ForgotPasswordCodePage()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    ],
  );
}
