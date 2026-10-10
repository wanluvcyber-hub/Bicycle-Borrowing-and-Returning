import 'package:supabase_flutter/supabase_flutter.dart';

/// ตัวเรียก Supabase กลางของทั้งแอป ทุกคนใช้ชื่อ `supabase` เหมือนกัน
/// (ใช้ได้หลัง `Supabase.initialize` ใน main.dart แล้วเท่านั้น)
SupabaseClient get supabase => Supabase.instance.client;
