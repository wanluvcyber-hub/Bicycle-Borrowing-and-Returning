import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/sign_out_button.dart';
import '../data/admin_repository.dart';
import '../state/admin_bikes_provider.dart';
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
  static const _titles = [
    'นำเข้ารายชื่อหอใน',
    'จักรยาน',
    'รหัสล็อก',
    'งานซ่อม',
  ];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminBikesProvider(AdminRepository())..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index]),
          actions: const [SignOutButton()],
        ),
        body: IndexedStack(
          index: _index,
          children: const [
            ImportStudentsPage(),
            BikesPage(),
            LocksPage(),
            RepairsPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.upload_file),
              label: 'นำเข้า',
            ),
            NavigationDestination(
              icon: Icon(Icons.pedal_bike),
              label: 'จักรยาน',
            ),
            NavigationDestination(icon: Icon(Icons.lock), label: 'รหัสล็อก'),
            NavigationDestination(icon: Icon(Icons.build), label: 'งานซ่อม'),
          ],
        ),
      ),
    );
  }
}
