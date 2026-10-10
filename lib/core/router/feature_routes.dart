import 'package:go_router/go_router.dart';

import '../../features/admin/admin_routes.dart';
import '../../features/auth/auth_routes.dart';
import '../../features/borrow/borrow_routes.dart';
import '../../features/guard/guard_routes.dart';

/// เส้นทางทั้งแอป = รวมของแต่ละฟีเจอร์ (ไฟล์เดียวที่ต้องเติมเมื่อฟีเจอร์ใหม่พร้อม)
final List<RouteBase> featureRoutes = [
  ...authRoutes,
  ...adminRoutes,
  ...borrowRoutes,
  ...guardRoutes,
];
