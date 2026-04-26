import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/detail_screen.dart';
import 'services/notification_service.dart';
import 'services/content_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await NotificationService.initialize();
  } catch (_) {}
  runApp(const ProviderScope(child: BookPulseApp()));
  // 웹: 푸시 클릭으로 ?filename=... 으로 진입한 경우 상세 화면으로 이동.
  if (kIsWeb) {
    _handleWebDeepLink();
  }
}

void _handleWebDeepLink() {
  final uri = Uri.base;
  final filename = uri.queryParameters['filename'];
  if (filename == null || filename.isEmpty) return;

  Future.delayed(const Duration(milliseconds: 300), () async {
    final summary = await ContentService().fetchByFilename(filename);
    final navigator = NotificationService.navigatorKey.currentState;
    if (summary == null || navigator == null) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => DetailScreen(summary: summary)),
    );
  });
}

class BookPulseApp extends StatelessWidget {
  const BookPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookPulse',
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5A27), // 책 느낌의 딥 그린
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'serif',
      ),
      home: const HomeScreen(),
    );
  }
}
