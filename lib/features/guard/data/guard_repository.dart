import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'guard_error.dart';
import 'guard_models.dart';

/// จุดเดียวที่โปรแกรมป้อมรปภ.คุยกับฐานข้อมูล (docs/database.md หัวข้อ 4.4, 4.5, 4.7)
abstract class GuardRepository {
  /// จักรยานทั้งหมด พร้อมรายการยืมที่ค้างอยู่ของแต่ละคัน
  Future<List<GuardBike>> fetchBikes();

  /// ทำให้รายการที่เลย due_at มี status = overdue (เรียกซ้ำได้)
  Future<void> markOverdue();

  /// รายการยืมที่ค้างของคันนี้ (null = ไม่มีใครยืม)
  Future<GuardLoan?> findActiveLoan(String bikeNo);

  Future<ReturnResult> returnBike({
    required String bikeNo,
    required ReturnCondition condition,
    String? note,
  });

  /// ประวัติของนิสิต (null = ไม่พบรหัสนิสิตนี้)
  Future<StudentHistory?> fetchHistory(String studentId);

  /// ส่งสัญญาณเมื่อ bikes หรือ loans เปลี่ยน (Realtime)
  Stream<void> changes();
}

const _loanSelect = '*, students(full_name, building, room, phone)';

class SupabaseGuardRepository implements GuardRepository {
  SupabaseGuardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<GuardBike>> fetchBikes() async {
    final bikeRows = await _client
        .from('bikes')
        .select('bike_no, station, status, note')
        .order('bike_no');
    final loanRows = await _client
        .from('loans')
        .select(_loanSelect)
        .isFilter('returned_at', null);

    final loanByBike = {
      for (final row in loanRows)
        row['bike_no'] as String: GuardLoan.fromJson(row),
    };
    return [
      for (final row in bikeRows)
        GuardBike.fromJson(row, activeLoan: loanByBike[row['bike_no']]),
    ];
  }

  @override
  Future<void> markOverdue() async {
    await _client.rpc('mark_overdue_loans');
  }

  @override
  Future<GuardLoan?> findActiveLoan(String bikeNo) async {
    final row = await _client
        .from('loans')
        .select(_loanSelect)
        .eq('bike_no', bikeNo)
        .isFilter('returned_at', null)
        .maybeSingle();
    return row == null ? null : GuardLoan.fromJson(row);
  }

  @override
  Future<ReturnResult> returnBike({
    required String bikeNo,
    required ReturnCondition condition,
    String? note,
  }) async {
    final res = await _client.rpc('return_bike', params: {
      'p_bike_no': bikeNo,
      'p_condition': condition.dbValue,
      'p_note': note,
    });
    return ReturnResult.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<StudentHistory?> fetchHistory(String studentId) async {
    final student = await _client
        .from('students')
        .select('student_id, full_name, late_count')
        .eq('student_id', studentId)
        .maybeSingle();
    if (student == null) return null;

    final rows = await _client
        .from('loans')
        .select()
        .eq('student_id', studentId)
        .order('borrowed_at', ascending: false);
    return StudentHistory(
      studentId: student['student_id'] as String,
      fullName: student['full_name'] as String,
      lateCount: (student['late_count'] as num).toInt(),
      loans: [for (final row in rows) GuardLoan.fromJson(row)],
    );
  }

  @override
  Stream<void> changes() {
    late final StreamController<void> controller;
    final subs = <StreamSubscription<Object?>>[];
    controller = StreamController<void>(
      onListen: () {
        subs.add(_client
            .from('bikes')
            .stream(primaryKey: ['bike_no'])
            .listen((_) => controller.add(null), onError: (_) {}));
        subs.add(_client
            .from('loans')
            .stream(primaryKey: ['loan_id'])
            .listen((_) => controller.add(null), onError: (_) {}));
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }
}

/// ข้อมูลปลอมไว้ทำ UI และเทสต์ ไม่ต้องต่อ Supabase
/// ทำงานเหมือน return_bike จริง: โยน GuardException ด้วยรหัสเดียวกับฐานข้อมูล
class FakeGuardRepository implements GuardRepository {
  FakeGuardRepository({DateTime? now}) {
    final t = now ?? DateTime.now();
    _bikes = {
      for (var i = 1; i <= 10; i++)
        'B${i.toString().padLeft(2, '0')}': GuardBike(
          bikeNo: 'B${i.toString().padLeft(2, '0')}',
          status: BikeStatus.available,
          station: 'ป้อมรปภ.',
        ),
    };
    _students = {
      '66000001': ('สมชาย ใจดี', 'อาคาร A', '101', '0811111111'),
      '66000002': ('สมหญิง รักเรียน', 'อาคาร B', '202', '0822222222'),
      '66000003': ('มานะ ตั้งใจ', 'อาคาร A', '305', '0833333333'),
    };
    _addLoan('B01', '66000001', t.subtract(const Duration(hours: 3)),
        t.add(const Duration(hours: 2)));
    _addLoan('B03', '66000003', t.subtract(const Duration(hours: 9)),
        t.subtract(const Duration(minutes: 30)));
    _bikes['B05'] = const GuardBike(
      bikeNo: 'B05',
      status: BikeStatus.broken,
      station: 'ป้อมรปภ.',
      note: 'เบรกหลังเสีย',
    );
  }

  late final Map<String, GuardBike> _bikes;
  late final Map<String, (String, String, String, String)> _students;
  final _loans = <GuardLoan>[];
  final _lateCounts = <String, int>{};
  final _changes = StreamController<void>.broadcast();
  var _nextLoanId = 1;

  void _addLoan(String bikeNo, String studentId, DateTime borrowedAt, DateTime dueAt) {
    final s = _students[studentId]!;
    final loan = GuardLoan(
      loanId: _nextLoanId++,
      studentId: studentId,
      bikeNo: bikeNo,
      borrowedAt: borrowedAt,
      dueAt: dueAt,
      studentName: s.$1,
      building: s.$2,
      room: s.$3,
      phone: s.$4,
    );
    _loans.add(loan);
    final bike = _bikes[bikeNo]!;
    _bikes[bikeNo] = GuardBike(
      bikeNo: bikeNo,
      status: BikeStatus.borrowed,
      station: bike.station,
      activeLoan: loan,
    );
  }

  @override
  Future<List<GuardBike>> fetchBikes() async => _bikes.values.toList();

  @override
  Future<void> markOverdue() async {}

  @override
  Future<GuardLoan?> findActiveLoan(String bikeNo) async {
    for (final loan in _loans) {
      if (loan.bikeNo == bikeNo && loan.isActive) return loan;
    }
    return null;
  }

  @override
  Future<ReturnResult> returnBike({
    required String bikeNo,
    required ReturnCondition condition,
    String? note,
  }) async {
    if (condition == ReturnCondition.damaged && (note ?? '').trim().isEmpty) {
      throw const GuardException('note_required');
    }
    final loan = await findActiveLoan(bikeNo);
    if (loan == null) throw const GuardException('no_active_loan');

    final now = DateTime.now();
    final late = now.isAfter(loan.dueAt);
    final index = _loans.indexOf(loan);
    _loans[index] = GuardLoan(
      loanId: loan.loanId,
      studentId: loan.studentId,
      bikeNo: loan.bikeNo,
      borrowedAt: loan.borrowedAt,
      dueAt: loan.dueAt,
      returnedAt: now,
      condition: condition,
      isLate: late,
      studentName: loan.studentName,
      building: loan.building,
      room: loan.room,
      phone: loan.phone,
    );
    final damaged = condition == ReturnCondition.damaged;
    _bikes[bikeNo] = GuardBike(
      bikeNo: bikeNo,
      status: damaged ? BikeStatus.broken : BikeStatus.available,
      station: _bikes[bikeNo]?.station,
      note: damaged ? note!.trim() : _bikes[bikeNo]?.note,
    );
    if (late) {
      _lateCounts[loan.studentId] = (_lateCounts[loan.studentId] ?? 0) + 1;
    }
    _changes.add(null);
    return ReturnResult(
      loanId: loan.loanId,
      studentId: loan.studentId,
      bikeNo: bikeNo,
      returnedAt: now,
      isLate: late,
      condition: condition,
    );
  }

  @override
  Future<StudentHistory?> fetchHistory(String studentId) async {
    final s = _students[studentId];
    if (s == null) return null;
    final loans = _loans.where((l) => l.studentId == studentId).toList()
      ..sort((a, b) => b.borrowedAt.compareTo(a.borrowedAt));
    return StudentHistory(
      studentId: studentId,
      fullName: s.$1,
      lateCount: _lateCounts[studentId] ?? 0,
      loans: loans,
    );
  }

  @override
  Stream<void> changes() => _changes.stream;
}
