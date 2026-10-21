import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart' show formatDuration;
import '../../../core/widgets/design_widgets.dart';
import '../../../core/widgets/message_view.dart';
import '../../auth/state/session_provider.dart';
import '../../reminder/data/reminder_schedule.dart' show formatThaiClock;
import '../data/admin_dashboard.dart';
import '../state/admin_dashboard_provider.dart';

/// แดชบอร์ดผู้ดูแล (ตัวเลขทั้งหมดคำนวณจาก bikes / loans / students อ่านอย่างเดียว)
/// [onOpenTab] ใช้พาไปแท็บอื่นของหน้าผู้ดูแล
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.onOpenTab});

  final ValueChanged<AdminTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminDashboardProvider>();
    final d = p.data;
    if (d == null) {
      if (p.error != null) {
        return MessageView(
          icon: Icons.cloud_off,
          message: p.error!,
          actions: [
            FilledButton(onPressed: p.load, child: const Text('ลองอีกครั้ง')),
          ],
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: p.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.error != null) ...[
            ErrorNotice(p.error!),
            const SizedBox(height: 12),
          ],
          _Header(d),
          const SizedBox(height: 8),
          _FleetSection(d),
          _QuickActions(onOpenTab: onOpenTab),
          _UrgentSection(d, onOpenTab: onOpenTab),
          _DailySummary(d),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// แท็บของหน้าผู้ดูแล (ดัชนีตรงกับเมนูล่าง)
enum AdminTab { dashboard, importStudents, bikes, locks, repairs }

class _Header extends StatelessWidget {
  const _Header(this.d);
  final AdminDashboard d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;
    final name = context.read<SessionProvider>().displayName ?? 'ผู้ดูแลระบบ';
    final overdueBar = d.total == 0 ? 0.0 : d.overdue / d.total;
    final inUseBar = d.total == 0
        ? 0.0
        : (d.inUse - d.overdue).clamp(0, d.total) / d.total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: 'กองบริการหอพักนิสิต ม.นเรศวร',
                color: scheme.onSurfaceVariant,
                background: scheme.surfaceContainerHighest,
                icon: Icons.verified_outlined,
              ),
              StatusPill(
                label: 'อัปเดต ${formatThaiClock(d.updatedAt)} น.',
                color: scheme.primary,
                background: scheme.surfaceContainerLowest,
                icon: Icons.sync,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('สวัสดี $name', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, color: scheme.onSurfaceVariant, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'อัตราการหมุนเวียนของจักรยาน',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${(d.utilization * 100).round()}%',
                      key: const Key('utilization'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Flexible(
                          flex: (inUseBar * 1000).round(),
                          child: Container(color: status.borrowed),
                        ),
                        Flexible(
                          flex: (overdueBar * 1000).round(),
                          child: Container(color: status.overdue),
                        ),
                        Flexible(
                          flex:
                              (1000 - ((inUseBar + overdueBar) * 1000).round())
                                  .clamp(0, 1000),
                          child: Container(
                            color: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'กำลังถูกยืม ${d.inUse} คัน',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'ว่าง ${d.available} คัน',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetSection extends StatelessWidget {
  const _FleetSection(this.d);
  final AdminDashboard d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'สรุปสถานะฝูงจักรยาน',
          trailing: Text(
            'รวม ${d.total} คัน',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.pedal_bike,
                  color: status.broken,
                  background: status.brokenContainer,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'จักรยานทั้งหมดในระบบ',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${d.total}',
                  key: const Key('totalBikes'),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(' คัน', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatTile(
                  width: w,
                  icon: Icons.check_circle,
                  label: 'พร้อมใช้',
                  value: d.available,
                  caption: 'ว่างที่จุดจอด',
                  color: status.available,
                  background: status.availableContainer,
                ),
                _StatTile(
                  width: w,
                  icon: Icons.pedal_bike,
                  label: 'ถูกยืม',
                  value: d.inUse,
                  caption: 'นิสิตกำลังใช้งาน',
                  color: status.borrowed,
                  background: status.borrowedContainer,
                ),
                _StatTile(
                  width: w,
                  icon: Icons.build,
                  label: 'รอซ่อม',
                  value: d.broken,
                  caption: 'งดให้บริการชั่วคราว',
                  color: status.broken,
                  background: status.brokenContainer,
                ),
                _StatTile(
                  width: w,
                  icon: Icons.alarm_off,
                  label: 'เกินเวลา',
                  value: d.overdue,
                  caption: d.overdue > 0
                      ? 'เกินกำหนดส่งคืน'
                      : 'ไม่มีรายการเกินเวลา',
                  color: status.overdue,
                  background: status.overdueContainer,
                  emphasize: d.overdue > 0,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.background,
    this.emphasize = false,
  });

  final double width;
  final IconData icon;
  final String label;
  final int value;
  final String caption;
  final Color color;
  final Color background;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label $value คัน',
      excludeSemantics: true,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: emphasize ? Border.all(color: color, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: tabularFigures,
              ),
            ),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTab});
  final ValueChanged<AdminTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('คำสั่งด่วน'),
        LayoutBuilder(
          builder: (context, c) {
            final half = (c.maxWidth - 8) / 2;
            Widget tile(
              double w,
              IconData icon,
              String title,
              String sub,
              AdminTab tab,
              Color bg,
            ) => SizedBox(
              width: w,
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => onOpenTab(tab),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconBadge(
                          icon: icon,
                          color: scheme.primary,
                          background: bg,
                          size: 48,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(sub, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            );
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                tile(
                  half,
                  Icons.upload_file,
                  'นำเข้ารายชื่อหอใน',
                  'อัปเดตนิสิตที่มีสิทธิ์ (CSV)',
                  AdminTab.importStudents,
                  scheme.surfaceContainer,
                ),
                tile(
                  half,
                  Icons.add_circle_outline,
                  'เพิ่มจักรยานใหม่',
                  'ลงทะเบียนคัน และตั้งรหัสล็อก',
                  AdminTab.bikes,
                  const Color(0xFFA3F69C),
                ),
                tile(
                  c.maxWidth,
                  Icons.lock_reset,
                  'เปลี่ยนรหัสล็อก',
                  'ดูและเปลี่ยนรหัสล็อกรายคัน',
                  AdminTab.locks,
                  scheme.surfaceContainer,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UrgentSection extends StatelessWidget {
  const _UrgentSection(this.d, {required this.onOpenTab});
  final AdminDashboard d;
  final ValueChanged<AdminTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;
    final count = d.overdue + d.broken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'เรื่องด่วนที่ต้องดำเนินการ',
          trailing: count == 0
              ? null
              : StatusPill(
                  label: '$count งาน',
                  color: Colors.white,
                  background: status.overdue,
                ),
        ),
        if (count == 0)
          Row(
            children: [
              Icon(Icons.task_alt, color: status.available, size: 20),
              const SizedBox(width: 8),
              Text(
                'ไม่มีรายการเกินเวลาหรือจักรยานชำรุด',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        for (final l in d.overdueLoans)
          _AccentCard(
            color: status.overdue,
            child: _OverdueContent(l, now: d.updatedAt),
          ),
        for (final b in d.brokenBikes)
          _AccentCard(
            color: status.broken,
            child: _BrokenContent(
              b,
              onRepairs: () => onOpenTab(AdminTab.repairs),
            ),
          ),
      ],
    );
  }
}

class _AccentCard extends StatelessWidget {
  const _AccentCard({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(padding: const EdgeInsets.all(14), child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverdueContent extends StatelessWidget {
  const _OverdueContent(this.l, {required this.now});
  final OverdueLoan l;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;
    final detail = l.roomLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusPill(
              label: 'เกินเวลา ${formatDuration(l.lateBy(now))}',
              color: status.overdue,
              background: status.overdueContainer,
              icon: Icons.alarm_off,
            ),
            const Spacer(),
            Icon(Icons.schedule, size: 16, color: status.overdue),
            const SizedBox(width: 4),
            Text(
              'กำหนด ${formatThaiClock(l.dueAt)} น.',
              style: theme.textTheme.bodySmall?.copyWith(color: status.overdue),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'จักรยาน ${l.bikeNo}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l.studentName ?? '-'} (${l.studentId})',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (detail.isNotEmpty)
                      Text(detail, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrokenContent extends StatelessWidget {
  const _BrokenContent(this.b, {required this.onRepairs});
  final BrokenBike b;
  final VoidCallback onRepairs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = context.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusPill(
              label: 'ชำรุด',
              color: status.broken,
              background: status.brokenContainer,
              icon: Icons.build,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'จักรยาน ${b.bikeNo}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (b.note ?? '').isEmpty ? 'ไม่มีหมายเหตุ' : 'อาการ: ${b.note}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRepairs,
          icon: const Icon(Icons.build_circle_outlined),
          label: const Text('ไปหน้างานซ่อม'),
        ),
      ],
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary(this.d);
  final AdminDashboard d;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = context.status;
    final rate = d.onTimeRate;
    Widget tile(String value, String label, Color fg, Color bg) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontFeatures: tabularFigures,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'สรุปผลการใช้งานประจำวัน',
          trailing: Text('วันนี้', style: theme.textTheme.bodyMedium),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      tile(
                        '${d.borrowedToday}',
                        'ยืมวันนี้\n(ครั้ง)',
                        scheme.onSurface,
                        scheme.surfaceContainer,
                      ),
                      const SizedBox(width: 8),
                      tile(
                        '${d.returnedOnTimeToday}',
                        'คืนตรงเวลา',
                        status.available,
                        status.availableContainer,
                      ),
                      const SizedBox(width: 8),
                      tile(
                        '${d.returnedLateToday}',
                        'คืนล่าช้า',
                        status.overdue,
                        status.overdueContainer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ดัชนีคืนตรงเวลา',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      rate == null
                          ? 'ยังไม่มีการคืนวันนี้'
                          : '${(rate * 100).toStringAsFixed(1)}%',
                      key: const Key('onTimeRate'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: rate == null
                            ? scheme.onSurfaceVariant
                            : status.available,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: rate ?? 0,
                    minHeight: 10,
                    color: status.available,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.badge_outlined, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${NumberFormat.decimalPattern().format(d.studentCount)} คน',
                              key: const Key('studentCount'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'นิสิตหอในที่ลงทะเบียนในระบบ',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
