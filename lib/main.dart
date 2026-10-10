import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/models/app_role.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/message_view.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/state/session_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const _EnvMissingApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: Env.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SessionProvider(SupabaseAuthRepository()),
        ),
      ],
      child: const BikeLoanApp(),
    ),
  );
}

class BikeLoanApp extends StatefulWidget {
  const BikeLoanApp({super.key});

  @override
  State<BikeLoanApp> createState() => _BikeLoanAppState();
}

class _BikeLoanAppState extends State<BikeLoanApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(context.read<SessionProvider>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<SessionProvider, AppRole?>((s) => s.role);
    return MaterialApp.router(
      title: 'ยืม-คืนจักรยานหอใน',
      theme: AppTheme.forRole(role),
      routerConfig: _router,
    );
  }
}

/// แสดงเมื่อยังไม่ได้ตั้ง env.json แทนการ crash
class _EnvMissingApp extends StatelessWidget {
  const _EnvMissingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.forRole(null),
      home: const Scaffold(
        body: SafeArea(
          child: MessageView(
            icon: Icons.settings_suggest,
            title: 'ยังไม่ได้ตั้งค่า Supabase',
            message:
                'คัดลอก env.example.json เป็น env.json แล้วใส่ URL กับ anon key '
                'จากนั้นรันด้วย\nflutter run --dart-define-from-file=env.json',
          ),
        ),
      ),
    );
  }
}
