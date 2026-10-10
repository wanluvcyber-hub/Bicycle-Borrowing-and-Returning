import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// ด่านเดียวที่คุยกับ plugin แจ้งเตือน แยกเป็น interface เพื่อให้เทสต์ ReminderService ได้โดยไม่ต้องมีมือถือ
abstract class NotificationGateway {
  /// เริ่ม plugin + timezone + ขอสิทธิ์ · เรียกซ้ำได้
  Future<void> init();

  /// ตั้งแจ้งเตือนให้เด้งที่เวลา [at]
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    bool urgent = false,
  });

  /// แสดงแถบนับถอยหลังที่ค้างอยู่ในแถบแจ้งเตือน (ระบบเดินเวลาเอง แอปปิดอยู่ก็ยังเดิน)
  /// ไปจนถึง [countdownTo] แล้วหายเอง
  Future<void> showCountdown({
    required int id,
    required String title,
    required String body,
    required DateTime countdownTo,
  });

  /// แสดง "เกินเวลาแล้ว" ทันที **แบบเงียบ** (ไม่มีเสียง/สั่น) ใช้ตอนซิงก์เจอรายการที่เลยกำหนดไปแล้ว
  /// เพื่อไม่ให้เด้งเสียงซ้ำทุกครั้งที่เปิดแอป · เสียงเตือนจริงมาจาก [schedule] ตอนถึง due_at
  Future<void> showOverdueStatus({
    required int id,
    required String title,
    required String body,
  });

  /// ตั้งเวลาแบบตรงเป๊ะได้ไหม (Android 12+ ผู้ใช้ต้องอนุญาต exact alarm)
  Future<bool> canScheduleExact();

  /// เปิดหน้าตั้งค่าของระบบให้ผู้ใช้อนุญาต exact alarm
  Future<void> requestExactAlarm();

  /// ยกเลิกทั้งอันที่รอเด้งและอันที่โชว์อยู่
  Future<void> cancel(int id);
}

/// ตัวจริง ใช้ `flutter_local_notifications` (v22)
class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initFuture;

  static const _reminderChannel = AndroidNotificationDetails(
    'loan_reminder',
    'เตือนก่อนถึงเวลาคืน',
    channelDescription: 'เตือนก่อนครบกำหนดคืนจักรยาน 21.00 น.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _urgentChannel = AndroidNotificationDetails(
    'loan_reminder_urgent',
    'เตือนด่วน (5 นาทีสุดท้าย)',
    channelDescription: 'เตือนแรงๆ เมื่อใกล้ครบกำหนดคืนจักรยาน',
    importance: Importance.max,
    priority: Priority.max,
  );

  @override
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    tzdata.initializeTimeZones();
    // due_at เป็นเวลาสัมบูรณ์ (UTC) อยู่แล้ว ตั้ง timezone เป็นเวลาไทยก็เพียงพอ
    // ไม่ว่ามือถือจะตั้งโซนเวลาอะไร เวลาเด้งจะไม่เพี้ยน
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_bike'),
      ),
    );

    // Android 13+ ต้องขอสิทธิ์ตอนรัน
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> canScheduleExact() async {
    await init();
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<void> requestExactAlarm() async {
    await init();
    await _android?.requestExactAlarmsPermission();
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    // ถ้าไม่ได้รับสิทธิ์ exact alarm ระบบอาจเลื่อนเวลาเด้งได้หลายนาที โดยเฉพาะตอนเครื่องหลับ (Doze)
    final exact = await canScheduleExact();
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    bool urgent = false,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: NotificationDetails(
        android: urgent ? _urgentChannel : _reminderChannel,
      ),
      androidScheduleMode: await _scheduleMode(),
    );
  }

  @override
  Future<void> showCountdown({
    required int id,
    required String title,
    required String body,
    required DateTime countdownTo,
  }) async {
    await init();
    final until = countdownTo.difference(DateTime.now());
    if (until <= Duration.zero) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'loan_countdown',
          'เวลาที่เหลือในการยืม',
          channelDescription: 'แสดงเวลานับถอยหลังจนถึงกำหนดคืนจักรยาน',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: true,
          when: countdownTo.millisecondsSinceEpoch,
          usesChronometer: true,
          chronometerCountDown: true,
          // หายเองเมื่อครบกำหนด แล้วแจ้งเตือน "เกินเวลา" (id อื่น) จะมาแทน
          timeoutAfter: until.inMilliseconds,
        ),
      ),
    );
  }

  @override
  Future<void> showOverdueStatus({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'loan_overdue_status',
          'สถานะเกินเวลา',
          channelDescription: 'แสดงว่าเลยกำหนดคืนจักรยานแล้ว (ไม่มีเสียง)',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
        ),
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }
}
