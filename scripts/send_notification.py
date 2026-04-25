"""
BookPulse - FCM 푸시 알림 발송 스크립트
GitHub Actions notify.yml 에서 실행됩니다.
"""

import os
import json
import re
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, messaging, firestore

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


def send_to_all_subscribers(title: str, body: str):
    """Firestore에 저장된 모든 FCM 토큰으로 푸시를 발송합니다."""
    db = firestore.client()
    tokens_ref = db.collection("fcm_tokens")
    tokens = [doc.to_dict()["token"] for doc in tokens_ref.stream()]

    if not tokens:
        print("⚠️  구독자가 없습니다.")
        return

    # FCM Multicast (한 번에 최대 500개)
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=f"📚 {title}", body=body),
        data={"type": "new_summary"},
        tokens=tokens,
    )

    response = messaging.send_each_for_multicast(message)
    print(f"✅ 발송 완료: 성공 {response.success_count} / 실패 {response.failure_count}")


# ── 실행 ─────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    init_firebase()
    content = get_latest_content()

    if content:
        print(f"📖 발송 콘텐츠: {content['title']}")
        send_to_all_subscribers(
            title=content["title"],
            body=content["summary"],
        )
