import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/design_widgets.dart';
import '../data/admin_repository.dart';
import '../data/student_import.dart';
import '../state/student_import_provider.dart';

/// นำเข้ารายชื่อหอใน: เลือก CSV → ตรวจ/ตัวอย่าง → นำเข้า → สรุป
class ImportStudentsPage extends StatelessWidget {
  const ImportStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentImportProvider(AdminRepository()),
      child: Consumer<StudentImportProvider>(
        builder: (context, p, _) => switch (p.stage) {
          ImportStage.pick => _PickStep(error: p.error),
          ImportStage.preview => _PreviewStep(p),
          ImportStage.importing => const Center(
            child: CircularProgressIndicator(),
          ),
          ImportStage.done => _DoneStep(p),
        },
      ),
    );
  }
}

class _PickStep extends StatefulWidget {
  const _PickStep({this.error});
  final String? error;

  @override
  State<_PickStep> createState() => _PickStepState();
}

class _PickStepState extends State<_PickStep> {
  String? _error;

  Future<void> _pick() async {
    final provider = context.read<StudentImportProvider>();
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      provider.loadCsv(file.name, utf8.decode(bytes, allowMalformed: true));
    } catch (e) {
      debugPrint('[import] pick: $e');
      if (mounted) {
        setState(() => _error = 'เปิดไฟล์ไม่สำเร็จ ลองเลือกไฟล์ใหม่');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error ?? widget.error;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'รูปแบบไฟล์ CSV (UTF-8 แถวแรกเป็นหัวคอลัมน์)',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'จำเป็น: ${kStudentCsvRequired.join(', ')}\n'
          'เสริม: ${kStudentCsvOptional.join(', ')}',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF04202B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const SelectableText(
            kStudentCsvExample,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'นำเข้าซ้ำได้: รหัสนิสิตที่มีอยู่แล้วจะถูกแก้ข้อมูล '
          'ส่วนสถานะยืนยันหอในและจำนวนครั้งที่คืนสายไม่ถูกแตะ',
          style: theme.textTheme.bodySmall,
        ),
        if (error != null) ...[const SizedBox(height: 12), ErrorNotice(error)],
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: _pick,
          icon: const Icon(Icons.upload_file),
          label: const Text('เลือกไฟล์ CSV'),
        ),
      ],
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep(this.p);
  final StudentImportProvider p;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = p.parsed!;
    final valid = parsed.validRows;
    final invalid = parsed.invalidRows;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p.fileName ?? '', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final e in parsed.fileErrors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ErrorNotice(e),
                ),
              if (parsed.ignoredColumns.isNotEmpty)
                Text(
                  'ข้ามคอลัมน์ที่ไม่รู้จัก: ${parsed.ignoredColumns.join(', ')}',
                  style: theme.textTheme.bodySmall,
                ),
              if (parsed.fileErrors.isEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      label: 'ผ่าน ${valid.length} แถว',
                      color: context.status.available,
                      icon: Icons.check_circle,
                    ),
                    StatusPill(
                      label: 'ไม่ผ่าน ${invalid.length} แถว',
                      color: invalid.isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : context.status.overdue,
                      icon: Icons.error_outline,
                    ),
                  ],
                ),
                if (p.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ErrorNotice(p.error!),
                  ),
                if (invalid.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'แถวที่ไม่ผ่าน (จะไม่ถูกนำเข้า)',
                    style: theme.textTheme.titleSmall,
                  ),
                  for (final r in invalid)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'แถว ${r.rowNumber}'
                        '${r.studentId != null ? ' · ${r.studentId}' : ''}',
                      ),
                      subtitle: Text(r.errors.join(', ')),
                    ),
                ],
                const SizedBox(height: 16),
                Text(
                  'ตัวอย่างแถวที่ผ่าน (แสดง 5 แถวแรก)',
                  style: theme.textTheme.titleSmall,
                ),
                for (final r in valid.take(5))
                  ListTile(
                    dense: true,
                    title: Text('${r.studentId} · ${r.fullName}'),
                    subtitle: Text(
                      [
                        r.data['building'],
                        r.data['room'],
                        r.data['email'],
                        r.data['semester'],
                      ].whereType<String>().join(' · '),
                    ),
                  ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: p.reset,
                  child: const Text('เลือกไฟล์ใหม่'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: p.canImport ? p.runImport : null,
                    child: Text('นำเข้า ${valid.length} แถว'),
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

class _DoneStep extends StatelessWidget {
  const _DoneStep(this.p);
  final StudentImportProvider p;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = p.summary!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: context.status.available,
              child: const Icon(Icons.check, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('นำเข้าเสร็จแล้ว', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(
              label: 'เพิ่มใหม่ ${s.added}',
              color: context.status.available,
              icon: Icons.person_add_alt,
            ),
            StatusPill(
              label: 'แก้ไข ${s.updated}',
              color: context.status.borrowed,
              icon: Icons.edit_outlined,
            ),
            StatusPill(
              label: 'ผิด ${s.issues.length}',
              color: s.issues.isEmpty
                  ? theme.colorScheme.onSurfaceVariant
                  : context.status.overdue,
              icon: Icons.error_outline,
            ),
          ],
        ),
        if (s.issues.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('แถวที่ไม่ได้นำเข้า', style: theme.textTheme.titleSmall),
          for (final i in s.issues)
            ListTile(
              dense: true,
              leading: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'แถว ${i.rowNumber}'
                '${i.studentId != null ? ' · ${i.studentId}' : ''}',
              ),
              subtitle: Text(i.reason),
            ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: p.reset,
          child: const Text('นำเข้าไฟล์อื่น'),
        ),
      ],
    );
  }
}
