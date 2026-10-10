import 'package:go_router/go_router.dart';

import 'presentation/login_page.dart';
import 'presentation/no_access_page.dart';
import 'presentation/splash_page.dart';

/// เส้นทางของฟีเจอร์ล็อกอิน (router กลางใน core รวมให้)
final List<RouteBase> authRoutes = [
  GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
  GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
  GoRoute(path: '/no-access', builder: (_, _) => const NoAccessPage()),
];
