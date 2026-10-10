import 'package:go_router/go_router.dart';

import '../reminder/presentation/reminder_scope.dart';
import 'presentation/borrow_home_page.dart';

/// เส้นทางของฝั่งนิสิต (router กลางกันไม่ให้บทบาทอื่นเข้า `/borrow`)
///
/// ครอบด้วย [ReminderScope] เพื่อต่อระบบแจ้งเตือนของคนที่ 4: ยืมสำเร็จ → ตั้งเตือน,
/// เปิดแอป/กลับจากพื้นหลัง → ซิงก์, ออกจากระบบ → ยกเลิกเตือน
final List<RouteBase> borrowRoutes = [
  GoRoute(
    path: '/borrow',
    builder: (_, _) => ReminderScope(
      builder: (_, reminder) => BorrowHomePage(
        onBorrowed: (loan) => reminder.onLoanStarted(
          loanId: loan.loanId,
          bikeNo: loan.bikeNo,
          borrowedAt: loan.borrowedAt,
          dueAt: loan.dueAt,
        ),
      ),
    ),
  ),
];
