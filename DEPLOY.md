# 남성초 회의실 예약 시스템 배포

## 배포 방식

이 프로젝트는 Firebase Hosting으로 배포할 수 있습니다.

- 화면 파일: `mrs_ns.html`
- 데이터: 기존 Firebase Firestore 유지
- 로그인: 기존 Firebase Authentication 유지
- 보안 규칙: `firestore.rules`
- 설치형 웹앱 파일: `manifest.webmanifest`, `sw.js`, `app-icon.svg`

이 방식은 크롬 전용 앱이 아니라 PWA(설치형 웹앱)입니다.
Chrome, Edge, Safari 같은 브라우저에서 열 수 있고, 지원되는 환경에서는 앱처럼 설치할 수 있습니다.

## 배포 명령

Firebase 로그인 후 아래 명령을 실행합니다.
배포 계정은 `leens@nsworld.net`입니다. 스크립트가 로그인 계정을 확인하고, 다른 계정이면 배포 전에 중단합니다.

```bash
./deploy.sh
```

화면만 먼저 배포하려면 아래 명령을 사용할 수 있습니다.

```bash
firebase deploy --only hosting
```

Firestore 보안 규칙까지 함께 배포하려면 아래 명령을 사용합니다.

```bash
firebase deploy --only hosting,firestore:rules
```

Firebase 로그인 화면에서 `Firebase CLI Login Failed`가 뜨면 현재 네트워크에서 `auth.firebase.tools` 접속이 막힌 상태일 수 있습니다.
`Your credentials are no longer valid` 또는 `Unable to authenticate using the provided code`가 뜨면 저장된 로그인 토큰이 만료된 상태입니다. 최신 `deploy.command`는 만료된 토큰을 자동으로 분리하고 새 로그인 코드만 받도록 되어 있습니다.
먼저 아래 파일을 실행하면 DNS, Firebase 로그인, 계정 확인, 배포 단계별 로그가 바탕화면에 저장됩니다.

```bash
./deploy-diagnose.command
```

그래도 로그인 단계에서 막히면 DNS/네트워크가 정상인 터미널에서 아래 명령으로 토큰을 만든 뒤 붙여 넣어 배포합니다.

```bash
firebase login:ci
FIREBASE_TOKEN='발급받은_토큰' ./deploy.sh
```

브라우저 로그인과 CI 토큰 발급이 둘 다 실패하면 서비스 계정 JSON 키로 배포합니다.
이 방식은 Firebase CLI 브라우저 로그인을 사용하지 않습니다.

```bash
./deploy-service-account.command
```

## 배포 후 확인할 것

- Firebase Authentication의 승인된 도메인에 배포 도메인이 포함되어 있는지 확인합니다.
- 기존 예약 데이터는 Hosting 배포로 삭제되지 않습니다.
- 기존 예약 취소 호환성을 맞추려면 `firestore.rules`도 함께 배포합니다.
- PC Chrome/Edge에서는 주소창 오른쪽 설치 버튼 또는 메뉴의 앱 설치를 확인합니다.
- iPhone/iPad에서는 Safari 공유 메뉴의 홈 화면에 추가를 사용합니다.
