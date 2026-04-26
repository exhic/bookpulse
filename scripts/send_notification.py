"""
BookPulse - FCM 푸시 알림 발송 스크립트
GitHub Actions notify.yml 에서 실행됩니다.
"""

import os
import json
import re
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, messaging

# 전체 구독자에게 보낼 때 사용하는 FCM 토픽 이름.
# 앱은 시작 시 이 토픽을 subscribeToTopic('all') 로 구독한다.
BROADCAST_TOPIC = "all"


# ── Firebase 초기화 ──────────────────────────────────────────────────────

def init_firebase():
    service_account_json = os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"]
    cred = credentials.Certificate(json.loads(service_account_json))
    firebase_admin.initialize_app(cred)


def get_latest_content() -> dict | None:
    """content/ 폴더에서 가장 최근 마크다운 파일을 파싱합니다."""
    content_dir = Path(__file__).parent.parent / "content"
    md_files = sorted(content_dir.glob("*.md"), reverse=True)

    if not md_files:
        print("⚠️  발행할 콘텐츠가 없습니다.")
        return None

    latest = md_files[0]
    text = latest.read_text(encoding="utf-8")

    # YAML frontmatter 파싱
    title_match = re.search(r'^title:\s*["\']?(.+?)["\']?\s*$', text, re.MULTILINE)
    summary_match = re.search(r'## 한 줄 요약\n(.+)', text)

    return {
        "filename": latest.name,
        "title": title_match.group(1) if title_match else "새 책 요약",
        "summary": summary_match.group(1).strip() if summary_match else "지금 확인해보세요!",
    }


def send_to_topic(title: str, body: str, filename: str):
    """전체 구독자(BROADCAST_TOPIC) 에게 푸시를 발송합니다."""
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

    if content:
        print(f"📖 발송 콘텐츠: {content['title']}")
        send_to_topic(
            title=content["title"],
            body=content["summary"],
            filename=content["filename"],
        )
