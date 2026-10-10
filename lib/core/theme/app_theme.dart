import 'package:flutter/material.dart';

import '../models/app_role.dart';

/// ธีมกลางตามดีไซน์ (stitch_custom_design_project/campus_mobility_material/DESIGN.md)
///
/// - สีประจำบทบาท: นิสิต=เขียว · ป้อมยาม=ส้ม · ผู้ดูแล=เทาน้ำเงิน (พื้นหลัง/พื้นผิวใช้ชุดเดียวกันทุกบทบาท)
/// - สีสถานะ (ว่าง/ถูกยืม/ชำรุด/เกินเวลา/คืนแล้ว) แยกจากสีบทบาท ใช้ผ่าน [AppStatusColors]
///   ฝั่งป้อมยามห้ามใช้ส้มเป็นสีเตือน ให้ใช้ `overdue` (แดง) เท่านั้น
/// - ฟอนต์: Prompt (หัวข้อ/ปุ่ม/ตัวเลข) + Noto Sans Thai (เนื้อหา) ฝังไว้ใน `assets/fonts/`
class AppTheme {
  const AppTheme._();

  static const studentColor = Color(0xFF2E7D32);
  static const guardColor = Color(0xFFEF6C00);
  static const adminColor = Color(0xFF546E7A);

  static const headingFont = 'Prompt';
  static const bodyFont = 'NotoSansThai';

  static Color seedFor(AppRole? role) => switch (role) {
    AppRole.guard => guardColor,
    AppRole.admin => adminColor,
    _ => studentColor,
  };

  /// พื้นผิวสีฟ้าอ่อนชุดเดียวกันทุกบทบาท (ตาม DESIGN.md)
  static const _surface = Color(0xFFF3FAFF);
  static const _onSurface = Color(0xFF021F29);

  static ColorScheme schemeFor(AppRole? role) {
    final seed = seedFor(role);
    final base = ColorScheme.fromSeed(seedColor: seed);
    final shared = base.copyWith(
      surface: _surface,
      surfaceDim: const Color(0xFFC3DEEC),
      surfaceBright: _surface,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFE6F6FF),
      surfaceContainer: const Color(0xFFD8F2FF),
      surfaceContainerHigh: const Color(0xFFD1ECFA),
      surfaceContainerHighest: const Color(0xFFCBE7F5),
      onSurface: _onSurface,
      onSurfaceVariant: const Color(0xFF40493D),
      outline: const Color(0xFF707A6C),
      outlineVariant: const Color(0xFFBFCABA),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF93000A),
    );
    return switch (role) {
      // นิสิต: ใช้ชุดเขียวตามดีไซน์
      null || AppRole.student => shared.copyWith(
        primary: const Color(0xFF0D631B),
        onPrimary: Colors.white,
        primaryContainer: studentColor,
        onPrimaryContainer: const Color(0xFFCBFFC2),
        secondary: const Color(0xFF005FAF),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF54A0FE),
        onSecondaryContainer: const Color(0xFF003567),
        tertiary: const Color(0xFF8E3D00),
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFFDBCA),
        onTertiaryContainer: const Color(0xFF331200),
      ),
      // ป้อมยาม/ผู้ดูแล: ปุ่มหลักเป็นสีบทบาทเต็มสี ตัวอักษรขาว
      AppRole.guard || AppRole.admin => shared.copyWith(
        primary: seed,
        onPrimary: Colors.white,
        tertiaryContainer: const Color(0xFFFFE0B2),
        onTertiaryContainer: const Color(0xFF4A2800),
      ),
    };
  }

  static TextTheme _textTheme(Color color) {
    TextStyle h(double size, double line, FontWeight w, [double ls = 0]) =>
        TextStyle(
          fontFamily: headingFont,
          fontSize: size,
          height: line / size,
          fontWeight: w,
          letterSpacing: ls,
          color: color,
        );
    TextStyle b(double size, double line, [FontWeight w = FontWeight.w400]) =>
        TextStyle(
          fontFamily: bodyFont,
          fontSize: size,
          height: line / size,
          fontWeight: w,
          color: color,
        );
    return TextTheme(
      // รหัสล็อก (Display Large ฉบับมือถือ) · ตัวเลขกว้างเท่ากัน ใช้ [tabular] ตอนแสดง
      displayLarge: h(44, 62, FontWeight.w700, 5.3),
      // เวลานับถอยหลัง HH:MM:SS
      displayMedium: h(34, 48, FontWeight.w600, 0.7),
      displaySmall: h(28, 40, FontWeight.w600),
      headlineLarge: h(32, 46, FontWeight.w600),
      headlineMedium: h(28, 40, FontWeight.w600),
      headlineSmall: h(24, 34, FontWeight.w600),
      titleLarge: h(22, 32, FontWeight.w500),
      titleMedium: h(16, 24, FontWeight.w500),
      titleSmall: h(14, 22, FontWeight.w500),
      bodyLarge: b(16, 24),
      bodyMedium: b(14, 22),
      bodySmall: b(12, 18),
      labelLarge: h(15, 22, FontWeight.w500),
      labelMedium: h(12, 18, FontWeight.w500),
      labelSmall: h(11, 16, FontWeight.w500),
    );
  }

  /// ธีมตามบทบาท (ยังไม่ล็อกอิน = ธีมนิสิต)
  static ThemeData forRole(AppRole? role) {
    final scheme = schemeFor(role);
    final text = _textTheme(scheme.onSurface);
    final isGuard = role == AppRole.guard;
    // ป้อมยามใช้ซ้ำทั้งวัน ปุ่มสูงอย่างน้อย 56dp ตามดีไซน์ ส่วนบทบาทอื่น 48dp
    final minHeight = isGuard ? 56.0 : 48.0;
    const stadium = StadiumBorder();
    final buttonText = text.labelLarge!.copyWith(fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: bodyFont,
      textTheme: text,
      extensions: const [AppStatusColors.standard],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(64, minHeight),
          shape: stadium,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, minHeight),
          shape: stadium,
          textStyle: buttonText,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(48, minHeight - 8),
          shape: stadium,
          textStyle: buttonText,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: stadium,
        extendedTextStyle: buttonText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isGuard ? 16 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        labelStyle: text.bodyMedium,
        hintStyle: text.bodyMedium!.copyWith(color: scheme.outline),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        // ตัวอักษรขาวเมื่อเลือก (พื้นสีบทบาทเข้ม) ไม่งั้นเข้มบนเข้มอ่านไม่ออก
        labelStyle: text.labelLarge!.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
        ),
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: Size(64, minHeight + 8),
          textStyle: buttonText,
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// ตัวเลขกว้างเท่ากัน กันเลขกระดิกตอนนับถอยหลัง/แสดงรหัสล็อก
const tabularFigures = [FontFeature.tabularFigures()];

/// สีสถานะ (แยกจากสีบทบาท) · ใช้: `context.status.available`
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.available,
    required this.availableContainer,
    required this.borrowed,
    required this.borrowedContainer,
    required this.broken,
    required this.brokenContainer,
    required this.overdue,
    required this.overdueContainer,
    required this.returned,
    required this.returnedContainer,
  });

  static const standard = AppStatusColors(
    available: Color(0xFF2E7D32),
    availableContainer: Color(0xFFE8F5E9),
    borrowed: Color(0xFF1565C0),
    borrowedContainer: Color(0xFFE3F2FD),
    broken: Color(0xFF424242),
    brokenContainer: Color(0xFFEEEEEE),
    overdue: Color(0xFFC62828),
    overdueContainer: Color(0xFFFFEBEE),
    returned: Color(0xFF689F38),
    returnedContainer: Color(0xFFF1F8E9),
  );

  final Color available, availableContainer;
  final Color borrowed, borrowedContainer;
  final Color broken, brokenContainer;
  final Color overdue, overdueContainer;
  final Color returned, returnedContainer;

  @override
  AppStatusColors copyWith() => this;

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) =>
      this;
}

extension AppStatusColorsContext on BuildContext {
  /// สีสถานะของธีมปัจจุบัน (ถ้าธีมไม่มี เช่นในเทสต์ ใช้ค่ามาตรฐาน)
  AppStatusColors get status =>
      Theme.of(this).extension<AppStatusColors>() ?? AppStatusColors.standard;
}
