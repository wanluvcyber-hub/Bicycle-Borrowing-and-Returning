import 'package:go_router/go_router.dart';

import 'presentation/admin_home_page.dart';

/// เส้นทางของฝั่งผู้ดูแลระบบ (router กลางกันไม่ให้บทบาทอื่นเข้า `/admin`)
final List<RouteBase> adminRoutes = [
  GoRoute(path: '/admin', builder: (_, _) => const AdminHomePage()),
];
