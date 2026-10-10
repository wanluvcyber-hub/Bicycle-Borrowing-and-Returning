import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_routes.dart';
import '../../features/auth/auth_routes.dart';
import '../../features/auth/presentation/sign_out_button.dart';

/// เส้นทางทั้งแอป = รวมของแต่ละฟีเจอร์ (ไฟล์เดียวที่ต้องเติมเมื่อฟีเจอร์ใหม่พร้อม)
///
/// คนที่ 2/3: ทำ `borrow_routes.dart` / `guard_routes.dart` ในโฟลเดอร์ฟีเจอร์ของตัวเอง
/// (ต้องมี path `/borrow` / `/guard` เป็นหน้าแรก) แล้วแทนที่บรรทัด _placeholder ด้านล่างด้วย
/// `...borrowRoutes,` / `...guardRoutes,`
final List<RouteBase> featureRoutes = [
  ...authRoutes,
  ...adminRoutes,
  _placeholder('/borrow', 'ฝั่งนิสิต (คนที่ 2)'),
  _placeholder('/guard', 'ฝั่งป้อมยาม (คนที่ 3)'),
];

GoRoute _placeholder(String path, String label) => GoRoute(
  path: path,
  builder: (_, _) => Scaffold(
    appBar: AppBar(title: Text(label), actions: const [SignOutButton()]),
    body: Center(child: Text('$label · ยังไม่พร้อม')),
  ),
);
