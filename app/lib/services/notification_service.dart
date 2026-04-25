import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// 앱 시작 시 한 번 호출
  static Future<void> initialize() async {
    // 알림 권한 요청
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 구독 토큰 저장
    await _saveToken();

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen((message) {
      // TODO: 인앱 알림 표시 (예: flutter_local_notifications)
      print('포그라운드 메시지: ${message.notification?.title}');
    });
  }

  static Future<void> _saveToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await _db.collection('fcm_tokens').doc(token).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
