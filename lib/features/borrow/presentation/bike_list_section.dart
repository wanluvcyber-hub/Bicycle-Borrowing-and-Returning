import 'package:flutter/material.dart';

import '../../../core/widgets/design_widgets.dart';
import '../data/borrow_models.dart';
import 'borrow_widgets.dart';

/// process 2.0: จำนวนคันว่าง + รายการทุกคัน (อัปเดตสดจาก Realtime) · กรอง ทั้งหมด/ว่าง ได้
class BikeListSection extends StatefulWidget {
  const BikeListSection({
    super.key,
    required this.bikes,
    required this.loading,
  });

  final List<BorrowBike> bikes;
  final bool loading;

  @override
  State<BikeListSection> createState() => _BikeListSectionState();
}

class _BikeListSectionState extends State<BikeListSection> {
  var _onlyAvailable = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bikes = widget.bikes;
    final availableCount = bikes
        .where((b) => b.status == BikeAvailability.available)
        .length;
    final shown = _onlyAvailable
        ? bikes.where((b) => b.status == BikeAvailability.available).toList()
        : bikes;
    final ratio = bikes.isEmpty ? 0.0 : availableCount / bikes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('จักรยานว่าง', style: theme.textTheme.titleLarge),
                  const SizedBox(width: 12),
                  Text(
                    '$availableCount',
                    key: const Key('availableCount'),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ' / ${bikes.length} คัน',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  color: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ยืมได้ก่อนเวลา 21:00 น. · คืนที่ป้อมยาม',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.list, size: 18),
              label: Text('ทั้งหมด (${bikes.length})'),
              selected: !_onlyAvailable,
              onSelected: (_) => setState(() => _onlyAvailable = false),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.check_circle_outline, size: 18),
              label: Text('ว่าง ($availableCount)'),
              selected: _onlyAvailable,
              onSelected: (_) => setState(() => _onlyAvailable = true),
            ),
          ],
        ),
        const SectionTitle('รายการจักรยาน'),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: widget.loading
                  ? const CircularProgressIndicator()
                  : Text(
                      bikes.isEmpty
                          ? 'ยังไม่มีข้อมูลจักรยาน'
                          : 'ตอนนี้ไม่มีจักรยานว่าง',
                    ),
            ),
          ),
        for (final bike in shown) _BikeTile(bike: bike),
      ],
    );
  }
}

class _BikeTile extends StatelessWidget {
  const _BikeTile({required this.bike});

  final BorrowBike bike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = availabilityColor(bike.status);
    final bg = availabilityBackground(bike.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconBadge(icon: Icons.pedal_bike, color: color, background: bg),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike.bikeNo,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          bike.station ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(
              label: bike.status.label,
              color: color,
              background: bg,
              icon: availabilityIcon(bike.status),
            ),
          ],
        ),
      ),
    );
  }
}
