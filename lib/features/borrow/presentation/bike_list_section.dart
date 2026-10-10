import 'package:flutter/material.dart';

import '../data/borrow_models.dart';
import 'borrow_widgets.dart';

/// process 2.0: จำนวนคันว่าง + รายการทุกคัน (อัปเดตสดจาก Realtime)
class BikeListSection extends StatelessWidget {
  const BikeListSection({super.key, required this.bikes, required this.loading});

  final List<BorrowBike> bikes;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final available =
        bikes.where((b) => b.status == BikeAvailability.available).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: studentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text('$available',
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: studentColor)),
              Text('คันที่ว่างตอนนี้ (จากทั้งหมด ${bikes.length} คัน)'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (bikes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('ยังไม่มีข้อมูลจักรยาน'),
            ),
          ),
        for (final bike in bikes)
          Card(
            child: ListTile(
              leading: const Icon(Icons.pedal_bike),
              title: Text(bike.bikeNo,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(bike.station ?? '-'),
              trailing: StatusChip(
                label: bike.status.label,
                color: availabilityColor(bike.status),
              ),
            ),
          ),
      ],
    );
  }
}
