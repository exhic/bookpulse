import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await NotificationService.initialize();
  } catch (_) {}
  runApp(const ProviderScope(child: BookPulseApp()));
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
