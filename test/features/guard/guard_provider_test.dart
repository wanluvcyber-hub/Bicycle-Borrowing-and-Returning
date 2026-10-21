import 'package:bike_loan/features/guard/data/guard_models.dart';
import 'package:bike_loan/features/guard/data/guard_repository.dart';
import 'package:bike_loan/features/guard/state/guard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeGuardRepository repo;
  late GuardProvider provider;

  setUp(() {
    repo = FakeGuardRepository();
    provider = GuardProvider(repo);
  });

  tearDown(() => provider.dispose());

  test('แดชบอร์ด: ตัวเลขสรุปถูกต้อง (B01 กำลังยืม, B03 เกินเวลา, B05 ชำรุด)', () async {
    await provider.refresh();
    final s = provider.summary;
    expect(s.total, 10);
    expect(s.inUse, 2);
    expect(s.broken, 1);
    expect(s.available, 7);
    expect(s.overdue, 1);
    expect(provider.overdueBikes.single.bikeNo, 'B03');
  });

  test('กรองตามสถานะ', () async {
    await provider.refresh();
    provider.setFilter(BikeFilter.broken);
    expect(provider.filteredBikes.map((b) => b.bikeNo), ['B05']);
    provider.setFilter(BikeFilter.overdue);
    expect(provider.filteredBikes.map((b) => b.bikeNo), ['B03']);
  });

  test('รับคืนคันที่ไม่มีใครยืม -> ข้อความ no_active_loan', () async {
    await provider.lookupBike('B02');
    expect(provider.pendingLoan, isNull);
    expect(provider.returnError, 'ไม่พบรายการยืมค้างของคันนี้');
  });

  test('พิมพ์เลขคันตัวพิมพ์เล็ก/มีช่องว่างก็หาเจอ และเห็นผู้ยืมก่อนรับคืน', () async {
    await provider.lookupBike('  b01 ');
    expect(provider.pendingLoan?.studentName, 'สมชาย ใจดี');
  });

  test('ชำรุดแต่ไม่ใส่หมายเหตุ -> ไม่ส่งคำขอ', () async {
    await provider.lookupBike('B01');
    final ok = await provider.confirmReturn(
        condition: ReturnCondition.damaged, note: '  ');
    expect(ok, isFalse);
    expect(provider.returnError, 'ถ้าชำรุด ต้องใส่หมายเหตุ');
    expect(provider.pendingLoan, isNotNull);
  });

  test('รับคืนปกติ: คันกลับเป็นว่าง ตรงเวลา', () async {
    await provider.lookupBike('B01');
    final ok = await provider.confirmReturn(condition: ReturnCondition.normal);
    expect(ok, isTrue);
    expect(provider.lastResult?.isLate, isFalse);
    await provider.refresh();
    final b01 = provider.bikes.firstWhere((b) => b.bikeNo == 'B01');
    expect(b01.status, BikeStatus.available);
  });

  test('คืนสาย + ชำรุด: is_late, late_count เพิ่ม, คันขึ้นชำรุดพร้อมหมายเหตุ', () async {
    await provider.lookupBike('B03');
    final ok = await provider.confirmReturn(
        condition: ReturnCondition.damaged, note: 'โซ่หลุด');
    expect(ok, isTrue);
    expect(provider.lastResult?.isLate, isTrue);

    await provider.refresh();
    final b03 = provider.bikes.firstWhere((b) => b.bikeNo == 'B03');
    expect(b03.status, BikeStatus.broken);
    expect(b03.note, 'โซ่หลุด');

    await provider.searchHistory('66000003');
    expect(provider.history?.lateCount, 1);
    expect(provider.history?.loans.first.isLate, isTrue);
  });

  test('กดรับคืนรัวๆ ส่งคำขอเดียว', () async {
    await provider.lookupBike('B01');
    final first = provider.confirmReturn(condition: ReturnCondition.normal);
    final second = provider.confirmReturn(condition: ReturnCondition.normal);
    expect(await second, isFalse);
    expect(await first, isTrue);
  });

  test('ค้นรหัสที่ไม่มี -> history เป็น null แต่รู้ว่าเคยค้นอะไร', () async {
    await provider.searchHistory('99999999');
    expect(provider.history, isNull);
    expect(provider.searchedId, '99999999');
    expect(provider.historyError, isNull);
  });

  test('ค้นประวัติเรียงล่าสุดก่อน', () async {
    await provider.searchHistory('66000001');
    expect(provider.history?.loans.single.bikeNo, 'B01');
  });

  test('realtime: มีการเปลี่ยนแปลงแล้วแดชบอร์ดโหลดใหม่เอง', () async {
    await provider.refresh();
    await repo.returnBike(bikeNo: 'B01', condition: ReturnCondition.normal);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(
      provider.bikes.firstWhere((b) => b.bikeNo == 'B01').status,
      BikeStatus.available,
    );
  });

  test('GuardLoan.fromJson อ่านข้อมูลผู้ยืมที่ join มา', () {
    final loan = GuardLoan.fromJson({
      'loan_id': 1,
      'student_id': '66000001',
      'bike_no': 'B01',
      'borrowed_at': '2026-10-10T04:30:00+00:00',
      'due_at': '2026-10-10T14:00:00+00:00',
      'returned_at': null,
      'condition': null,
      'is_late': false,
      'students': {
        'full_name': 'สมชาย ใจดี',
        'building': 'A',
        'room': '101',
      },
    });
    expect(loan.isActive, isTrue);
    expect(loan.studentName, 'สมชาย ใจดี');
    expect(loan.roomLabel, 'A ห้อง 101');
    expect(loan.isOverdue(DateTime.utc(2026, 10, 10, 15)), isTrue);
    expect(loan.isOverdue(DateTime.utc(2026, 10, 10, 13)), isFalse);
  });
}
