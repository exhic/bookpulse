import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_summary.dart';
import '../screens/detail_screen.dart';
import 'content_service.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// MaterialApp 에 연결되는 글로벌 네비게이터 키.
  /// 푸시 탭 핸들러는 BuildContext 가 없으므로 이 키로 화면을 푸시한다.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// 전체 구독자 발송용 FCM 토픽. send_notification.py 의 BROADCAST_TOPIC 과 일치.
  static const _broadcastTopic = 'all';

  /// 앱 시작 시 한 번 호출
  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _saveToken();
    await _messaging.subscribeToTopic(_broadcastTopic);

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
    final token = await _messaging.getToken();
    if (token == null) return;

    await _db.collection('fcm_tokens').doc(token).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
