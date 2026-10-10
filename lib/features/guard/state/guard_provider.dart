import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/guard_error.dart';
import '../data/guard_models.dart';
import '../data/guard_repository.dart';

class GuardProvider extends ChangeNotifier {
  GuardProvider(this._repo, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _changesSub = _repo.changes().listen((_) => refresh(), onError: (_) {});
  }

  final GuardRepository _repo;
  final DateTime Function() _clock;
  StreamSubscription<void>? _changesSub;
  var _disposed = false;

  // ---------- แดชบอร์ด ----------
  List<GuardBike> _bikes = const [];
  BikeFilter _filter = BikeFilter.all;
  bool _loading = false;
  bool _loadedOnce = false;
  bool _refreshQueued = false;
  Future<void>? _inflight;
  String? _dashboardError;

  List<GuardBike> get bikes => _bikes;
  BikeFilter get filter => _filter;
  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  String? get dashboardError => _dashboardError;
  DateTime get now => _clock();

  DashboardSummary get summary => DashboardSummary.from(_bikes, now);

  List<GuardBike> get overdueBikes =>
      _bikes.where((b) => b.isOverdue(now)).toList();

  List<GuardBike> get filteredBikes {
    final t = now;
    return _bikes.where((b) => _filter.matches(b, t)).toList();
  }

  void setFilter(BikeFilter value) {
    _filter = value;
    notifyListeners();
  }

  /// เปิดแดชบอร์ด / กดรีเฟรช: อัปเดตสถานะเกินเวลาก่อน แล้วดึงรายการใหม่
  Future<void> refresh() {
    if (_loading) {
      _refreshQueued = true; // มีการเปลี่ยนแปลงระหว่างโหลด ให้โหลดซ้ำอีกรอบ
      return _inflight!;
    }
    return _inflight = _load();
  }

  Future<void> _load() async {
    _loading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      try {
        await _repo.markOverdue();
      } catch (_) {
        // ไม่สำคัญ: เกินเวลาตัดสินจาก due_at ฝั่งแอปอยู่แล้ว
      }
      _bikes = await _repo.fetchBikes();
      _loadedOnce = true;
    } catch (e) {
      _dashboardError = guardMessageOf(e);
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
    if (_refreshQueued && !_disposed) {
      _refreshQueued = false;
      await refresh();
    }
  }

  // ---------- รับคืน ----------
  GuardLoan? _pendingLoan;
  String? _returnError;
  bool _lookingUp = false;
  bool _returning = false;
  ReturnResult? _lastResult;

  GuardLoan? get pendingLoan => _pendingLoan;
  String? get returnError => _returnError;
  bool get lookingUp => _lookingUp;
  bool get returning => _returning;
  ReturnResult? get lastResult => _lastResult;

  static String normalizeBikeNo(String input) => input.trim().toUpperCase();

  /// ขั้นที่ 1: ป้อมยามต้องเห็นผู้ยืมก่อนเสมอ
  Future<void> lookupBike(String input) async {
    final bikeNo = normalizeBikeNo(input);
    _pendingLoan = null;
    _lastResult = null;
    _returnError = null;
    if (bikeNo.isEmpty) {
      _returnError = 'กรุณากรอกหรือสแกนเลขจักรยาน';
      notifyListeners();
      return;
    }
    _lookingUp = true;
    notifyListeners();
    try {
      final loan = await _repo.findActiveLoan(bikeNo);
      if (loan == null) {
        _returnError = guardMessageOf(const GuardException('no_active_loan'));
      } else {
        _pendingLoan = loan;
      }
    } catch (e) {
      _returnError = guardMessageOf(e);
    } finally {
      _lookingUp = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clearReturn() {
    _pendingLoan = null;
    _returnError = null;
    _lastResult = null;
    notifyListeners();
  }

  /// ขั้นที่ 2: ยืนยันรับคืน · ล็อกไว้ระหว่างรอ กดรัวๆ ก็ส่งคำขอเดียว
  Future<bool> confirmReturn({
    required ReturnCondition condition,
    String? note,
  }) async {
    final loan = _pendingLoan;
    if (loan == null || _returning) return false;
    final trimmed = note?.trim() ?? '';
    if (condition == ReturnCondition.damaged && trimmed.isEmpty) {
      _returnError = guardMessageOf(const GuardException('note_required'));
      notifyListeners();
      return false;
    }

    _returning = true;
    _returnError = null;
    notifyListeners();
    try {
      _lastResult = await _repo.returnBike(
        bikeNo: loan.bikeNo,
        condition: condition,
        note: trimmed.isEmpty ? null : trimmed,
      );
      _pendingLoan = null;
      unawaited(refresh());
      return true;
    } catch (e) {
      _returnError = guardMessageOf(e);
      return false;
    } finally {
      _returning = false;
      if (!_disposed) notifyListeners();
    }
  }

  // ---------- ค้นประวัติ ----------
  StudentHistory? _history;
  String? _searchedId;
  bool _searching = false;
  String? _historyError;

  StudentHistory? get history => _history;
  String? get searchedId => _searchedId;
  bool get searching => _searching;
  String? get historyError => _historyError;

  /// ค้นแล้วไม่พบ: history เป็น null แต่ searchedId มีค่า หน้าจอจึงบอก "ไม่พบ" ได้
  Future<void> searchHistory(String input) async {
    final id = input.trim();
    if (id.isEmpty || _searching) return;
    _searching = true;
    _historyError = null;
    _searchedId = id;
    _history = null;
    notifyListeners();
    try {
      _history = await _repo.fetchHistory(id);
    } catch (e) {
      _historyError = guardMessageOf(e);
    } finally {
      _searching = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _changesSub?.cancel();
    super.dispose();
  }
}
