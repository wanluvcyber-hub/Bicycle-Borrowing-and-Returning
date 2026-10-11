import 'package:go_router/go_router.dart';

import 'presentation/guard_home_page.dart';

/// เส้นทางของฝั่งป้อมรปภ. (router กลางกันไม่ให้บทบาทอื่นเข้า `/guard`)
final List<RouteBase> guardRoutes = [
  GoRoute(path: '/guard', builder: (_, _) => const GuardHomePage()),
];
