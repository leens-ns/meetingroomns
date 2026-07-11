#!/usr/bin/env bash
set -euo pipefail
trap 'status=$?; if [[ $status -ne 0 ]]; then echo; echo "오류로 중단되었습니다. 위 메시지를 확인해 주세요."; read -r -p "Enter 키를 누르면 종료합니다. " _; fi' EXIT

cd "$(dirname "$0")"

REPO="leens-ns/meetingroomns"
SECRET_NAME="FIREBASE_SERVICE_ACCOUNT_JSON_B64"
DEFAULT_KEY="$HOME/Downloads/namsung-meeting-room-7811f-firebase-adminsdk-fbsvc-239a88496a.json"

echo "GitHub Actions 원격 배포를 준비합니다."
echo "로컬 Google 인증 서버 연결이 끊길 때 사용하는 방식입니다."
echo

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI가 설치되어 있지 않습니다."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub 로그인이 필요합니다. 브라우저가 열리면 GitHub 계정으로 로그인하세요."
  gh auth login -h github.com -p https -w
fi

KEY_PATH="${GOOGLE_APPLICATION_CREDENTIALS:-}"
if [[ -z "$KEY_PATH" && -f "$DEFAULT_KEY" ]]; then
  KEY_PATH="$DEFAULT_KEY"
fi

if [[ -z "$KEY_PATH" ]]; then
  echo "서비스 계정 JSON 파일을 이 창에 드래그해서 놓고 Enter를 누르세요."
  read -r -p "JSON 파일 경로: " KEY_PATH
  KEY_PATH="${KEY_PATH#\"}"
  KEY_PATH="${KEY_PATH%\"}"
  KEY_PATH="${KEY_PATH#\'}"
  KEY_PATH="${KEY_PATH%\'}"
  KEY_PATH="${KEY_PATH#file://}"
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "JSON 파일을 찾을 수 없습니다: $KEY_PATH"
  exit 1
fi

echo
echo "1. GitHub Secret 등록"
base64 < "$KEY_PATH" | tr -d '\n' | gh secret set "$SECRET_NAME" --repo "$REPO"

echo
echo "2. 배포 파일 검사"
node - <<'NODE'
const fs = require('fs');
const html = fs.readFileSync('mrs_ns.html', 'utf8');
const scripts = [...html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/gi)].map(m => m[1]);
scripts.forEach((script, index) => {
  try { new Function(script); }
  catch (error) {
    console.error(`mrs_ns.html script ${index + 1}: ${error.message}`);
    process.exit(1);
  }
});
for (const file of ['firebase.json', '.firebaserc', 'manifest.webmanifest']) {
  JSON.parse(fs.readFileSync(file, 'utf8'));
}
new Function(fs.readFileSync('sw.js', 'utf8'));
console.log('검사 완료');
NODE

echo
echo "3. GitHub에 변경사항 업로드"
git add mrs_ns.html firestore.rules firebase.json .firebaserc manifest.webmanifest sw.js app-icon.svg app-icon-192.png app-icon-512.png apple-touch-icon.png DEPLOY.md .github/workflows/firebase-deploy.yml
git commit -m "Update meeting room reservation app" || true
git pull --rebase origin main
git push origin HEAD

echo
echo "4. GitHub Actions 배포 실행"
gh workflow run firebase-deploy.yml --repo "$REPO"

echo
echo "5. 배포 완료까지 확인"
sleep 5
RUN_ID="$(gh run list --repo "$REPO" --workflow firebase-deploy.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
  echo "실행된 GitHub Actions 배포를 찾지 못했습니다."
  echo "아래 주소에서 직접 상태를 확인해 주세요."
  echo "https://github.com/$REPO/actions/workflows/firebase-deploy.yml"
  exit 1
fi

echo "배포 실행 번호: $RUN_ID"
if ! gh run watch "$RUN_ID" --repo "$REPO" --exit-status; then
  echo
  echo "배포가 실패했습니다. 실패 로그를 출력합니다."
  gh run view "$RUN_ID" --repo "$REPO" --log-failed || true
  exit 1
fi

echo
echo "배포가 완료되었습니다."
echo "예약 시스템:"
echo "https://namsung-meeting-room-7811f.web.app/?v=account-management"
echo
echo "배포 기록:"
echo "https://github.com/$REPO/actions/runs/$RUN_ID"
read -r -p "Enter 키를 누르면 종료합니다. " _
