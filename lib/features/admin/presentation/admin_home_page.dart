import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/design_widgets.dart';
import '../../auth/presentation/sign_out_button.dart';
import '../data/admin_repository.dart';
import '../state/admin_bikes_provider.dart';
import '../state/admin_dashboard_provider.dart';
import 'admin_dashboard_page.dart';
import 'bikes_page.dart';
import 'import_students_page.dart';
import 'locks_page.dart';
import 'repairs_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // ลำดับตรงกับ [AdminTab]
  static const _titles = [
    'แดชบอร์ด',
    'นำเข้ารายชื่อหอใน',
    'จักรยาน',
    'รหัสล็อก',
    'งานซ่อม',
  ];
  int _index = 0;

  void _open(BuildContext context, int i) {
    setState(() => _index = i);
    // กลับมาแท็บแดชบอร์ด → ตัวเลขต้องเป็นปัจจุบัน (อาจมีการแก้จักรยาน/ซ่อมเสร็จจากแท็บอื่น)
    if (i == AdminTab.dashboard.index) {
      context.read<AdminDashboardProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AdminBikesProvider(AdminRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminDashboardProvider(AdminRepository())..load(),
        ),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: BrandTitle(subtitle: 'ผู้ดูแลระบบ · ${_titles[_index]}'),
            actions: [
              if (_index == AdminTab.dashboard.index)
                IconButton(
                  tooltip: 'รีเฟรช',
                  onPressed: context.read<AdminDashboardProvider>().load,
                  icon: const Icon(Icons.refresh),
                ),
              const SignOutButton(),
              const SizedBox(width: 4),
            ],
          ),
          body: IndexedStack(
            index: _index,
            children: [
              AdminDashboardPage(onOpenTab: (tab) => _open(context, tab.index)),
              const ImportStudentsPage(),
              const BikesPage(),
              const LocksPage(),
              const RepairsPage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => _open(context, i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'แดชบอร์ด',
              ),
              NavigationDestination(
                icon: Icon(Icons.upload_file_outlined),
                selectedIcon: Icon(Icons.upload_file),
                label: 'นำเข้า',
              ),
              NavigationDestination(
                icon: Icon(Icons.pedal_bike_outlined),
                selectedIcon: Icon(Icons.pedal_bike),
                label: 'จักรยาน',
              ),
              NavigationDestination(
                icon: Icon(Icons.lock_outline),
                selectedIcon: Icon(Icons.lock),
                label: 'รหัสล็อก',
              ),
              NavigationDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build),
                label: 'งานซ่อม',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
