# 📚 BookPulse

> AI가 책을 읽고, 세상과 연결하고, 당신에게 전달한다.

주 1~3회, AI가 선별한 책의 핵심 인사이트를 모바일 푸시로 받아보는 퍼블릭 구독 서비스.

## 구조

```
scripts/generate_summary.py   ← 로컬에서 실행: AI 책 요약 생성
         ↓ git push
content/*.md                  ← 책 요약 마크다운 파일
         ↓ GitHub Actions
Firebase Hosting              ← Flutter Web 자동 배포
         ↓ cron
Firebase Cloud Messaging      ← 구독자 전원 푸시 알림
         ↓
Flutter App (iOS/Android/Web) ← 사용자
```

## 시작하기

### 1. 환경 설정
```bash
pip install anthropic
export ANTHROPIC_API_KEY=sk-ant-...
```

### 2. 책 요약 생성
```bash
# 요약 생성만
python scripts/generate_summary.py --book "사피엔스" --author "유발 하라리"

# 생성 후 바로 GitHub push
python scripts/generate_summary.py --book "총균쇠" --author "재레드 다이아몬드" --push
```

### 3. Flutter 앱 실행
```bash
cd app
flutter pub get
flutter run
```

## Firebase 설정
1. [Firebase Console](https://console.firebase.google.com)에서 프로젝트 생성
2. Hosting, Firestore, Cloud Messaging 활성화
3. GitHub Secrets에 추가:
   - `FIREBASE_SERVICE_ACCOUNT` (deploy용)
   - `FIREBASE_SERVICE_ACCOUNT_JSON` (notify용)
   - `FIREBASE_PROJECT_ID`

## 기획서
→ [BookPulse_기획서.md](../BookPulse_기획서.md)
