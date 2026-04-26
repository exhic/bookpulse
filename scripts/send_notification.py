"""
BookPulse - FCM 푸시 알림 발송 스크립트
GitHub Actions notify.yml 에서 실행됩니다.

발송 전략 (B안):
1. Firestore 의 fcm_tokens 컬렉션에서 토큰 전체를 읽는다.
2. 토픽 'all' 에 일괄 가입(subscribe_to_topic)시킨다 — 이미 가입된 토큰은 무시.
3. topic='all' 한 번 send 로 전 구독자에게 fan-out.
   웹 SDK 는 클라이언트 토픽 구독을 지원하지 않아 서버에서 처리한다.
"""

import os
import json
import re
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, messaging, firestore

BROADCAST_TOPIC = "all"
FCM_TOPIC_BATCH_SIZE = 1000  # Admin SDK subscribe_to_topic 한 번 호출 제한


# ── Firebase 초기화 ──────────────────────────────────────────────────────

def init_firebase():
    service_account_json = os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"]
    cred = credentials.Certificate(json.loads(service_account_json))
    firebase_admin.initialize_app(cred)


def get_latest_content() -> dict | None:
    content_dir = Path(__file__).parent.parent / "content"
    md_files = sorted(content_dir.glob("*.md"), reverse=True)

    if not md_files:
        print("⚠️  발행할 콘텐츠가 없습니다.")
        return None

    latest = md_files[0]
    text = latest.read_text(encoding="utf-8")

    title_match = re.search(r'^title:\s*["\']?(.+?)["\']?\s*$', text, re.MULTILINE)
    summary_match = re.search(r'## 한 줄 요약\n(.+)', text)

    return {
        "filename": latest.name,
        "title": title_match.group(1) if title_match else "새 책 요약",
        "summary": summary_match.group(1).strip() if summary_match else "지금 확인해보세요!",
    }


def auto_subscribe_tokens_to_topic():
    """Firestore 의 모든 토큰을 BROADCAST_TOPIC 에 가입시킨다.

    이미 가입된 토큰을 다시 호출해도 부작용 없음 (FCM 측에서 중복 무시).
    실패 토큰은 로그만 남긴다 — 발송 자체는 토픽 단위라 일부 실패해도 진행.
    """
    db = firestore.client()
    tokens = [doc.to_dict().get("token") for doc in db.collection("fcm_tokens").stream()]
    tokens = [t for t in tokens if t]

    if not tokens:
        print("ℹ️  Firestore 에 등록된 토큰이 없습니다 — 토픽 발송만 수행합니다.")
        return

    print(f"🔗 토픽 가입 처리: 토큰 {len(tokens)} 개")
    success = 0
    failure = 0
    for i in range(0, len(tokens), FCM_TOPIC_BATCH_SIZE):
        batch = tokens[i : i + FCM_TOPIC_BATCH_SIZE]
        resp = messaging.subscribe_to_topic(batch, BROADCAST_TOPIC)
        success += resp.success_count
        failure += resp.failure_count
    print(f"   → 성공 {success} / 실패 {failure}")


def send_to_topic(title: str, body: str, filename: str):
    message = messaging.Message(
        topic=BROADCAST_TOPIC,
        notification=messaging.Notification(title=f"📚 {title}", body=body),
        data={
            "type": "new_summary",
            "filename": filename,
            "title": title,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
    )

    message_id = messaging.send(message)
    print(f"✅ 발송 완료 (topic={BROADCAST_TOPIC}): {message_id}")


# ── 실행 ─────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    init_firebase()

    content = get_latest_content()
    if not content:
        raise SystemExit(0)

    print(f"📖 발송 콘텐츠: {content['title']}")
    auto_subscribe_tokens_to_topic()
    send_to_topic(
        title=content["title"],
        body=content["summary"],
        filename=content["filename"],
    )
