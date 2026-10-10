import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/borrow_models.dart';
import '../data/borrow_repository.dart';
import '../state/borrow_provider.dart';
import 'active_loan_card.dart';
import 'bike_list_section.dart';
import 'borrow_widgets.dart';
import 'confirm_borrow_page.dart';
import 'scan_page.dart';

/// หน้าหลักนิสิต · คนที่ 1 เรียกใช้จาก router เมื่อล็อกอินเป็นนิสิตที่ผูกสิทธิ์แล้ว
/// ไม่ส่ง [repository] = ใช้ Supabase จริง (ต้อง Supabase.initialize แล้ว)
/// [onBorrowed] = จุดต่อ "ตั้งเตือน 20.30 / 20.50" ของคนที่ 4
class BorrowHomePage extends StatelessWidget {
  const BorrowHomePage({
    super.key,
    this.repository,
    this.onBorrowed,
    this.onSignOut,
  });

  final BorrowRepository? repository;
  final void Function(MyLoan loan)? onBorrowed;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BorrowProvider(
        repository ?? SupabaseBorrowRepository(Supabase.instance.client),
        onBorrowed: onBorrowed,
      )..start(),
      child: _HomeScaffold(onSignOut: onSignOut),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({this.onSignOut});

  final Future<void> Function()? onSignOut;

  Future<void> _scan(BuildContext context) async {
    final provider = context.read<BorrowProvider>();
    final navigator = Navigator.of(context);
    final qr = await navigator
        .push<String>(MaterialPageRoute(builder: (_) => const ScanPage()));
    if (qr == null) return;
    provider.clearBorrowError();
    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: ConfirmBorrowPage(qrCode: qr),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BorrowProvider>();
    final loan = p.myLoan;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.profile == null ? 'ยืมจักรยาน' : 'สวัสดี ${p.profile!.fullName}'),
        backgroundColor: studentColor,
        actions: [
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: onSignOut ?? () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: loan == null
          ? FloatingActionButton.extended(
              backgroundColor: studentColor,
              onPressed: () => _scan(context),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('สแกน QR ยืม'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: p.refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (p.loadError != null) ...[
              ErrorBanner(p.loadError!),
              const SizedBox(height: 12),
            ],
            if (loan != null)
              ActiveLoanCard(loan: loan, clock: () => p.now)
            else
              BikeListSection(
                bikes: p.bikes,
                loading: p.loading || !p.loadedOnce,
              ),
          ],
        ),
      ),
    );
  }
}
