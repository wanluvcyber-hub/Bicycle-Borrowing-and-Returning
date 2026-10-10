import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/guard_repository.dart';
import '../state/guard_provider.dart';
import 'dashboard_page.dart';
import 'guard_widgets.dart';
import 'history_page.dart';
import 'return_page.dart';

/// หน้าหลักของป้อมยาม (3 แท็บ) · คนที่ 1 เรียกใช้จาก router เมื่อล็อกอินเป็น guard
/// ไม่ส่ง [repository] = ใช้ Supabase จริง (ต้อง Supabase.initialize แล้ว)
class GuardHomePage extends StatelessWidget {
  const GuardHomePage({super.key, this.repository, this.onSignOut});

  final GuardRepository? repository;

  /// ไม่ส่ง = เรียก Supabase auth.signOut() เอง
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GuardProvider(
        repository ?? SupabaseGuardRepository(Supabase.instance.client),
      )..refresh(),
      child: _GuardScaffold(onSignOut: onSignOut),
    );
  }
}

class _GuardScaffold extends StatefulWidget {
  const _GuardScaffold({this.onSignOut});

  final Future<void> Function()? onSignOut;

  @override
  State<_GuardScaffold> createState() => _GuardScaffoldState();
}

class _GuardScaffoldState extends State<_GuardScaffold> {
  var _index = 0;

  static const _titles = ['แดชบอร์ด', 'รับคืน', 'ค้นประวัติ'];
  static const _pages = [DashboardPage(), ReturnPage(), HistoryPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ป้อมยาม · ${_titles[_index]}'),
        backgroundColor: guardColor,
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'รีเฟรช',
              onPressed: context.read<GuardProvider>().refresh,
              icon: const Icon(Icons.refresh),
            ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed:
                widget.onSignOut ?? () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'แดชบอร์ด'),
          NavigationDestination(icon: Icon(Icons.assignment_return), label: 'รับคืน'),
          NavigationDestination(icon: Icon(Icons.history), label: 'ค้นประวัติ'),
        ],
      ),
    );
  }
}
