import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/detail_screen.dart';
import 'content_service.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// 웹 푸시 토큰 발급에 필요한 VAPID 공개키. 노출돼도 안전.
  static const _vapidKey =
      'BLmH6ZVr5ymrN5opSh1J3WKriftHSL51MNrScFLF9urttU2XkC0vEwynSLK3B10c8tJ2t8nEQWdsjrW_EMwH--4';

  /// MaterialApp 에 연결되는 글로벌 네비게이터 키.
  /// 푸시 탭 핸들러는 BuildContext 가 없으므로 이 키로 화면을 푸시한다.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// 앱 시작 시 한 번 호출
  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _saveToken();

    // 포그라운드 메시지: 그냥 로그만. (인앱 배너는 필요해지면 추가)
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('포그라운드 메시지: ${message.notification?.title}');
    });

    // 백그라운드에서 알림 탭 → 앱이 살아있는 상태
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // 앱이 종료된 상태에서 알림 탭 → 콜드 스타트
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  static Future<void> _saveToken() async {
    final token = kIsWeb
        ? await _messaging.getToken(vapidKey: _vapidKey)
        : await _messaging.getToken();
    if (token == null) return;

    await _db.collection('fcm_tokens').doc(token).set({
      'token': token,
      'platform': kIsWeb ? 'web' : defaultPlatform(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String defaultPlatform() {
    return defaultTargetPlatform.name; // 'android', 'iOS', etc.
  }

  static Future<void> _handleTap(RemoteMessage message) async {
    final filename = message.data['filename'] as String?;
    if (filename == null) return;

    final summary = await ContentService().fetchByFilename(filename);
    if (summary == null) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(builder: (_) => DetailScreen(summary: summary)),
    );
  }
}
