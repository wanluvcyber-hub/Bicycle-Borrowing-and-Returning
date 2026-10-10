/// ค่าตั้งค่าที่ส่งเข้ามาตอนรันด้วย `--dart-define-from-file=env.json`
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// กรอกครบและไม่ใช่ค่าตัวอย่างจาก env.example.json
  static bool get isConfigured =>
      _isReal(supabaseUrl) && _isReal(supabaseAnonKey);

  static bool _isReal(String v) => v.isNotEmpty && !v.contains('YOUR-');
}
