import 'package:bike_loan/features/borrow/data/borrow_error.dart';
import 'package:bike_loan/features/borrow/data/borrow_models.dart';
import 'package:bike_loan/features/borrow/data/borrow_repository.dart';
import 'package:bike_loan/features/borrow/state/borrow_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeBorrowRepository repo;
  late BorrowProvider provider;
  late List<MyLoan> reminded;

  setUp(() async {
    repo = FakeBorrowRepository();
    reminded = [];
    provider = BorrowProvider(repo, onBorrowed: reminded.add);
    await provider.start();
    await pumpEventQueue();
  });

  tearDown(() => provider.dispose());

  test('2.0: แสดงจักรยานทั้งหมดและนับคันว่าง (B02 ถูกยืม, B05 ชำรุด)', () {
    expect(provider.bikes.length, 10);
    expect(provider.availableBikes.length, 8);
    expect(provider.profile?.studentId, '66000001');
  });

  test('2.0 realtime: คนอื่นยืม/คืนแล้วรายการอัปเดตเอง', () async {
    repo.setBikeStatus('B01', BikeAvailability.borrowed);
    await pumpEventQueue();
    expect(provider.availableBikes.length, 7);
    repo.setBikeStatus('B01', BikeAvailability.available);
    await pumpEventQueue();
    expect(provider.availableBikes.length, 8);
  });

  test('3.0: ยืมสำเร็จได้รหัสล็อกและกำหนดคืน 21.00 น. + เรียกตั้งเตือน', () async {
    final outcome = await provider.confirmBorrow(' B01 ');
    expect(outcome, BorrowOutcome.success);
    expect(provider.myLoan?.bikeNo, 'B01');
    expect(provider.myLoan?.lockCode, '0111');
    expect(provider.myLoan?.dueAt.hour, 21);
    expect(provider.myLoan?.dueAt.minute, 0);
    expect(reminded.single.bikeNo, 'B01');
  });

  test('ยืมซ้ำทั้งที่มีคันค้าง -> already_borrowing ไม่ crash', () async {
    await provider.confirmBorrow('B01');
    final outcome = await provider.confirmBorrow('B03');
    expect(outcome, BorrowOutcome.failed);
    expect(provider.borrowError, 'คุณมีจักรยานที่ยืมค้างอยู่ ต้องคืนก่อน');
    expect(provider.myLoan?.bikeNo, 'B01');
  });

  test('คันที่คนอื่นยืมอยู่ / คันชำรุด -> bike_not_available', () async {
    for (final bike in ['B02', 'B05']) {
      expect(await provider.confirmBorrow(bike), BorrowOutcome.failed);
      expect(provider.borrowError, 'จักรยานคันนี้ไม่ว่าง');
    }
    expect(provider.hasActiveLoan, isFalse);
  });

  test('QR ที่ไม่ใช่ของระบบ -> bike_not_found', () async {
    expect(await provider.confirmBorrow('X99'), BorrowOutcome.failed);
    expect(provider.borrowError, 'ไม่พบจักรยานคันนี้ ลองสแกนอีกครั้ง');
    expect(await provider.confirmBorrow('   '), BorrowOutcome.failed);
    expect(provider.borrowError, 'ไม่พบจักรยานคันนี้ ลองสแกนอีกครั้ง');
  });

  test('ยืมหลัง 21.00 น. -> after_hours', () async {
    repo.afterHours = true;
    expect(await provider.confirmBorrow('B01'), BorrowOutcome.failed);
    expect(provider.borrowError, 'เลยเวลา 21.00 น. แล้ว ยืมไม่ได้');
  });

  test('ยังไม่ผูกสิทธิ์ -> not_verified', () async {
    repo.profile = null;
    expect(await provider.confirmBorrow('B01'), BorrowOutcome.failed);
    expect(provider.borrowError, 'บัญชีนี้ยังไม่ได้ยืนยันสิทธิ์หอใน');
  });

  test('เน็ตหลุดก่อนถึงเซิร์ฟเวอร์ -> บอกให้ลองใหม่ และยังไม่มีรายการ', () async {
    repo.failNextBorrowBeforeServer = true;
    expect(await provider.confirmBorrow('B01'), BorrowOutcome.failed);
    expect(provider.borrowError, networkErrorMessage);
    expect(provider.hasActiveLoan, isFalse);
    expect(reminded, isEmpty);
  });

  test('เน็ตหลุดหลังเซิร์ฟเวอร์สร้างรายการแล้ว -> เช็ก get_my_active_loan แล้วถือว่าสำเร็จ',
      () async {
    repo.dropNextBorrowResponse = true;
    expect(await provider.confirmBorrow('B01'), BorrowOutcome.success);
    expect(provider.myLoan?.bikeNo, 'B01');
    expect(provider.myLoan?.lockCode, '0111');
    expect(provider.borrowError, isNull);
    expect(reminded.single.bikeNo, 'B01');
  });

  test('กดยืนยันรัวๆ ส่งคำขอเดียว', () async {
    final first = provider.confirmBorrow('B01');
    final second = provider.confirmBorrow('B01');
    expect(await second, BorrowOutcome.failed);
    expect(await first, BorrowOutcome.success);
    expect(repo.borrowCalls, 1);
  });

  test('ปิดแอปแล้วเปิดใหม่ตอนกำลังยืม -> ยังเห็นรหัสล็อกเดิม', () async {
    await provider.confirmBorrow('B01');
    final reopened = BorrowProvider(repo);
    await reopened.start();
    expect(reopened.myLoan?.bikeNo, 'B01');
    expect(reopened.myLoan?.lockCode, '0111');
    reopened.dispose();
  });

  test('ป้อมรปภ.รับคืนแล้ว การ์ดรายการค้างหายเอง', () async {
    await provider.confirmBorrow('B01');
    repo.returnMyLoan();
    await pumpEventQueue();
    expect(provider.hasActiveLoan, isFalse);
  });

  group('แก้เบอร์โทรของตัวเอง', () {
    test('โหลดเบอร์โทรมากับข้อมูลนิสิต', () {
      expect(provider.profile?.phone, '0800000001');
    });

    test('บันทึกสำเร็จ: ตัดขีด/ช่องว่างออก และหน้าจอได้เบอร์ใหม่ทันที', () async {
      expect(await provider.updatePhone(' 081-234 5678 '), isNull);
      expect(provider.profile?.phone, '0812345678');
      expect(provider.profile?.studentId, '66000001');
      expect(provider.savingPhone, isFalse);
    });

    test('เบอร์ผิดรูปแบบ -> invalid_phone และเบอร์เดิมไม่เปลี่ยน', () async {
      for (final bad in ['', '12345', '1812345678', '08123456789', '08x2345678']) {
        expect(
          await provider.updatePhone(bad),
          'เบอร์โทรไม่ถูกต้อง ต้องเป็นเบอร์มือถือ 10 หลัก ขึ้นต้นด้วย 0',
          reason: bad,
        );
      }
      expect(provider.profile?.phone, '0800000001');
    });

    test('ยังไม่ผูกสิทธิ์ -> not_verified', () async {
      repo.profile = null;
      expect(
        await provider.updatePhone('0812345678'),
        'บัญชีนี้ยังไม่ได้ยืนยันสิทธิ์หอใน',
      );
    });

    test('เน็ตหลุด -> บอกให้ลองใหม่ และเบอร์เดิมไม่เปลี่ยน', () async {
      repo.failNextPhoneUpdate = true;
      expect(await provider.updatePhone('0812345678'), networkErrorMessage);
      expect(provider.profile?.phone, '0800000001');
    });

    test('กดบันทึกรัวๆ ส่งคำขอเดียว', () async {
      final first = provider.updatePhone('0812345678');
      final second = provider.updatePhone('0899999999');
      await Future.wait([first, second]);
      expect(repo.phoneUpdateCalls, 1);
      expect(provider.profile?.phone, '0812345678');
    });
  });

  test('คำขอที่ล้มเหลวด้วยเหตุผลของเซิร์ฟเวอร์ไม่ถูกมองเป็นเน็ตหลุด', () {
    expect(borrowErrorMessage(const BorrowException('after_hours')),
        'เลยเวลา 21.00 น. แล้ว ยืมไม่ได้');
    expect(borrowErrorMessage(const BorrowException('whatever')),
        unknownErrorMessage);
    expect(borrowErrorMessage(Exception('socket')), networkErrorMessage);
  });

  test('MyLoan: เวลาที่เหลือคำนวณจาก due_at และเกินเวลาเมื่อเลยกำหนด', () {
    final loan = MyLoan.fromJson({
      'loan_id': 1,
      'bike_no': 'B01',
      'lock_code': '0111',
      'borrowed_at': '2026-10-10T04:30:00+00:00',
      'due_at': '2026-10-10T14:00:00+00:00',
    });
    expect(loan.remaining(DateTime.utc(2026, 10, 10, 12)), const Duration(hours: 2));
    expect(loan.isOverdue(DateTime.utc(2026, 10, 10, 13)), isFalse);
    expect(loan.isOverdue(DateTime.utc(2026, 10, 10, 14, 1)), isTrue);
    expect(loan.toString().contains('0111'), isFalse);
  });
}
