import 'package:go_router/go_router.dart';

import '../../features/auth/state/session_provider.dart';
import '../models/app_role.dart';
import 'feature_routes.dart';

const _publicPaths = {'/splash', '/login', '/no-access'};

/// path ที่แต่ละบทบาทเข้าได้ (ที่เหลือจะถูกพากลับหน้าหลักของบทบาท)
const _roleRoots = {
  AppRole.student: '/borrow',
  AppRole.guard: '/guard',
  AppRole.admin: '/admin',
};

bool _isUnder(String location, String root) =>
    location == root || location.startsWith('$root/');

/// ตัดสินว่าต้องพาไปไหน (null = อยู่ที่เดิมได้) แยกเป็นฟังก์ชันล้วนเพื่อเทสต์ง่าย
String? redirectFor(SessionProvider session, String location) {
  switch (session.status) {
    case SessionStatus.loading:
    case SessionStatus.error:
      return location == '/splash' ? null : '/splash';
    case SessionStatus.signedOut:
      return location == '/login' ? null : '/login';
    case SessionStatus.noAccess:
      return location == '/no-access' ? null : '/no-access';
    case SessionStatus.ready:
      final role = session.role!;
      final root = _roleRoots[role]!;
      if (_publicPaths.contains(location) || !_isUnder(location, root)) {
        return root;
      }
      return null;
  }
}

/// สร้าง router ของทั้งแอป · เส้นทางของแต่ละฟีเจอร์ประกอบมาจาก `featureRoutes`
GoRouter createAppRouter(SessionProvider session) => GoRouter(
  initialLocation: '/splash',
  refreshListenable: session,
  redirect: (context, state) => redirectFor(session, state.uri.path),
  routes: featureRoutes,
);
