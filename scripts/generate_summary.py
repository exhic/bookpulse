"""
BookPulse - AI 책 요약 생성 스크립트
사용법: python generate_summary.py --book "사피엔스" --author "유발 하라리"
"""

import anthropic
import yaml
import argparse
import subprocess
from datetime import datetime
from pathlib import Path

# ── 설정 ────────────────────────────────────────────────────────────────
CONTENT_DIR = Path(__file__).parent.parent / "content"
CONTENT_DIR.mkdir(exist_ok=True)

SYSTEM_PROMPT = """당신은 책의 핵심을 간결하게 전달하는 북 큐레이터입니다.
독자가 책을 읽지 않아도 핵심 통찰을 얻을 수 있도록,
그리고 책을 읽고 싶은 동기를 가질 수 있도록 요약을 작성합니다."""

USER_PROMPT_TEMPLATE = """
다음 책에 대해 아래 형식의 마크다운 요약을 작성해 주세요.

책: {title}
저자: {author}
{extra_info}

---
형식:
```markdown
---
title: "{title}"
author: "{author}"
date: {date}
categories: [분류1, 분류2]  # 사회/역사/과학/경제/철학 중 해당하는 것
tags: [태그1, 태그2, 태그3]
---

## 한 줄 요약
(책 전체를 1~2문장으로)

## 핵심 내용
1. (핵심 포인트 1)
2. (핵심 포인트 2)
3. (핵심 포인트 3)

## 사회/역사/과학과의 연결
- **사회**: (현대 사회와의 연결점)
- **역사**: (역사적 맥락)
- **과학/기술**: (과학적 관점)

## 오늘의 인사이트
(독자가 오늘 하루 곱씹어볼 한 가지 생각)

## 이런 분께 추천
(어떤 사람에게 특히 유용한지 1~2줄)
```
"""

# ── 메인 함수 ────────────────────────────────────────────────────────────

def generate_summary(title: str, author: str, extra_info: str = "") -> str:
    """Claude API를 호출해 책 요약을 생성합니다."""
    client = anthropic.Anthropic()  # ANTHROPIC_API_KEY 환경변수 사용

    prompt = USER_PROMPT_TEMPLATE.format(
        title=title,
        author=author,
        date=datetime.now().strftime("%Y-%m-%d"),
        extra_info=extra_info,
    )

    message = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=2000,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": prompt}],
    )

    return message.content[0].text


def save_and_push(title: str, content: str, auto_push: bool = False):
    """마크다운 파일로 저장하고 git push합니다."""
    date_str = datetime.now().strftime("%Y%m%d")
    # 파일명에 쓸 수 없는 문자 제거
    safe_title = title.replace(" ", "-").replace("/", "-")
    filename = f"{date_str}-{safe_title}.md"
    filepath = CONTENT_DIR / filename

    # 코드블록 안의 마크다운 추출
    if "```markdown" in content:
        content = content.split("```markdown")[1].split("```")[0].strip()

    filepath.write_text(content, encoding="utf-8")
    print(f"✅ 저장 완료: {filepath}")

    if auto_push:
        try:
            repo_root = Path(__file__).parent.parent
            subprocess.run(["git", "add", str(filepath)], cwd=repo_root, check=True)
            subprocess.run(
                ["git", "commit", "-m", f"content: {title} 요약 추가"],
                cwd=repo_root, check=True,
            )
            subprocess.run(["git", "push"], cwd=repo_root, check=True)
            print("🚀 GitHub에 push 완료!")
        except subprocess.CalledProcessError as e:
            print(f"⚠️  Git push 실패: {e}")

    return filepath


# ── CLI ──────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="BookPulse AI 책 요약 생성")
    parser.add_argument("--book", required=True, help="책 제목")
    parser.add_argument("--author", required=True, help="저자")
    parser.add_argument("--info", default="", help="추가 정보 (선택)")
    parser.add_argument("--push", action="store_true", help="생성 후 자동 git push")
    args = parser.parse_args()

    print(f"📖 '{args.book}' 요약 생성 중...")
    summary = generate_summary(args.book, args.author, args.info)
    save_and_push(args.book, summary, auto_push=args.push)
