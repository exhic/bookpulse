// BookPulse - FCM 백그라운드 푸시 핸들러 (PWA / 웹)
// 이 파일은 Firebase Hosting 배포 시 도메인 루트(/firebase-messaging-sw.js)
// 에서 서빙되어야 한다.

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDz047Kgz1FZb0c5hV-UQqkR7TxgTsL8xY',
  appId: '1:66071509812:web:7a47b7a746a059de818361',
  messagingSenderId: '66071509812',
  projectId: 'bookpulse-58e07',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? '📚 BookPulse';
  const body = payload.notification?.body ?? '';
  const filename = payload.data?.filename ?? '';

  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    data: { filename, click_action: payload.data?.click_action ?? '' },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const filename = event.notification.data?.filename;
  const target = filename ? `/?filename=${encodeURIComponent(filename)}` : '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((wins) => {
      for (const w of wins) {
        if ('focus' in w) {
          w.navigate(target);
          return w.focus();
        }
      }
      if (clients.openWindow) return clients.openWindow(target);
    }),
  );
});
