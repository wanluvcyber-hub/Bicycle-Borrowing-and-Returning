import 'package:bike_loan/features/borrow/data/borrow_repository.dart';
import 'package:bike_loan/features/borrow/presentation/borrow_home_page.dart';
import 'package:bike_loan/features/borrow/presentation/edit_phone_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatPhone: 10 หลักใส่ขีด รูปแบบอื่นคงเดิม', () {
    expect(formatPhone('0812345678'), '081-234-5678');
    expect(formatPhone('+66812345678'), '+66812345678');
  });

  testWidgets('นิสิตเห็นเบอร์ตัวเอง แก้แล้วหน้าหลักอัปเดต', (tester) async {
    final repo = FakeBorrowRepository();
    await tester.pumpWidget(
      MaterialApp(home: BorrowHomePage(repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.text('โทร 080-000-0001'), findsOneWidget);

    await tester.tap(find.byTooltip('แก้ไขเบอร์โทร'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '0800000001'), findsOneWidget);

    // เบอร์ผิดรูปแบบ: กล่องยังเปิดอยู่และบอกเหตุผล
    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.textContaining('เบอร์โทรไม่ถูกต้อง'), findsOneWidget);
    expect(repo.profile?.phone, '0800000001');

    await tester.enterText(find.byType(TextField), '081-234-5678');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.byType(EditPhoneDialog), findsNothing);
    expect(find.text('โทร 081-234-5678'), findsOneWidget);
    expect(find.text('บันทึกเบอร์โทรแล้ว'), findsOneWidget);
    expect(repo.profile?.phone, '0812345678');
  });
}
