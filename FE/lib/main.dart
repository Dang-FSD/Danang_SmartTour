import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_colors.dart';
import 'presentation/screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo biến môi trường từ .env
  await EnvConfig.init();

  // 2. Khởi tạo Supabase (hoặc chạy Local Mode nếu chưa cấu hình)
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: DaNangSmartTourApp(),
    ),
  );
}

class DaNangSmartTourApp extends StatelessWidget {
  const DaNangSmartTourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DaNang SmartTour AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          secondary: AppColors.goldenSand,
          surface: Colors.white,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
