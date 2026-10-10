import 'package:bike_loan/core/models/loan.dart';
import 'package:bike_loan/features/reminder/data/active_loan_source.dart';
import 'package:bike_loan/features/reminder/data/notification_gateway.dart';

class ScheduledCall {
  ScheduledCall(this.id, this.at, this.title, this.body, this.urgent);
  final int id;
  final DateTime at;
  final String title;
  final String body;
  final bool urgent;
}

/// แทน plugin แจ้งเตือน: จำว่าอะไรถูกตั้ง/แสดง/ยกเลิก
class FakeGateway implements NotificationGateway {
  final scheduled = <int, ScheduledCall>{};
  final countdowns = <int, DateTime>{};
  final cancelled = <int>[];
  final overdueStatus = <int, String>{};
  int initCalls = 0;
  bool exactAllowed = false;
  int exactRequests = 0;

  @override
  Future<void> init() async => initCalls++;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    bool urgent = false,
  }) async {
    scheduled[id] = ScheduledCall(id, at, title, body, urgent);
  }

  @override
  Future<void> showCountdown({
    required int id,
    required String title,
    required String body,
    required DateTime countdownTo,
  }) async {
    countdowns[id] = countdownTo;
  }

  @override
  Future<void> showOverdueStatus({
    required int id,
    required String title,
    required String body,
  }) async {
    overdueStatus[id] = body;
  }

  @override
  Future<bool> canScheduleExact() async => exactAllowed;

  @override
  Future<void> requestExactAlarm() async => exactRequests++;

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
    countdowns.remove(id);
  }
}

class FakeLoanSource implements ActiveLoanSource {
  FakeLoanSource([this.loan]);
  ActiveLoan? loan;
  Object? error;
  int calls = 0;

  @override
  Future<ActiveLoan?> fetchActiveLoan() async {
    calls++;
    if (error != null) throw error!;
    return loan;
  }
}

ActiveLoan loanDueAt(
  DateTime due, {
  String bikeNo = 'B01',
  LoanStatus status = LoanStatus.borrowing,
}) => ActiveLoan(
  loanId: 1,
  bikeNo: bikeNo,
  lockCode: '0111',
  borrowedAt: due.subtract(const Duration(hours: 3)),
  dueAt: due,
  status: status,
);
