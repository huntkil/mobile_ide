#!/bin/bash

# ==========================================
# Cursor AI 화면 표시 스크립트
# ==========================================
# Author: Mobile IDE Team
# Version: 1.0.0

echo "=========================================="
echo "  Cursor AI 화면 표시"
echo "=========================================="
echo ""

echo "1단계: 기존 Cursor AI 프로세스 확인..."
cursor_pids=$(ps aux | grep -E "(cursor|AppRun)" | grep -v grep | awk '{print $2}')
if [ -n "$cursor_pids" ]; then
    echo "기존 Cursor AI 프로세스 발견, 종료 중..."
    echo "$cursor_pids" | xargs kill -9 2>/dev/null || echo "프로세스 종료 실패 (무시됨)"
    sleep 3
else
    echo "기존 Cursor AI 프로세스 없음"
fi

echo ""
echo "2단계: X11 환경 변수 설정..."
export DISPLAY=:1
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
export XDG_SESSION_TYPE="x11"
export XDG_CURRENT_DESKTOP="X-Generic"

echo ""
echo "3단계: 간단한 테스트 창 실행..."
# 기본 X11 도구로 테스트 창 생성
if command -v xmessage &>/dev/null; then
    xmessage -geometry 400x200+100+100 "Cursor AI 곧 시작됩니다..." &
    sleep 2
fi

echo ""
echo "4단계: Ubuntu 환경에서 Cursor AI 실행..."
proot-distro login ubuntu -- bash -c "
echo '=== Ubuntu 환경에서 Cursor AI 실행 ==='
cd /home/cursor-ide

# 환경 변수 설정
export DISPLAY=:1
export XDG_RUNTIME_DIR=\"\$HOME/.runtime-cursor\"
export XDG_SESSION_TYPE=\"x11\"
export XDG_CURRENT_DESKTOP=\"X-Generic\"
export LIBGL_ALWAYS_SOFTWARE=1
export QT_X11_NO_MITSHM=1

# 런타임 디렉토리 생성
mkdir -p \"\$XDG_RUNTIME_DIR\"
chmod 700 \"\$XDG_RUNTIME_DIR\"

echo '디렉토리 확인:'
ls -la

echo '실행 파일 확인:'
ls -la squashfs-root/AppRun

echo 'Cursor AI 실행 중...'
# 더 많은 옵션으로 실행
./squashfs-root/AppRun \
  --no-sandbox \
  --disable-gpu \
  --disable-software-rasterizer \
  --single-process \
  --disable-dev-shm-usage \
  --disable-background-timer-throttling \
  --disable-renderer-backgrounding \
  --disable-backgrounding-occluded-windows \
  --disable-features=TranslateUI \
  --max-old-space-size=1024 \
  --js-flags='--max-old-space-size=1024' \
  --force-device-scale-factor=1 \
  --high-dpi-support=0 \
  --enable-features=UseOzonePlatform \
  --ozone-platform=x11 &

echo 'Cursor AI 프로세스 시작됨'
sleep 5

# 프로세스 확인
ps aux | grep -E '(cursor|AppRun)' | grep -v grep || echo 'Cursor AI 프로세스 없음'
"

echo ""
echo "5단계: 윈도우 관리 및 포커스 설정..."
sleep 5

# X11 도구로 윈도우 관리
export DISPLAY=:1
if command -v xwininfo &>/dev/null; then
    echo "실행 중인 윈도우 확인:"
    xwininfo -root -tree 2>/dev/null | grep -E "(Cursor|cursor)" || echo "Cursor 윈도우 찾을 수 없음"
fi

echo ""
echo "6단계: 최종 프로세스 확인..."
echo "모든 관련 프로세스:"
ps aux | grep -E "(cursor|AppRun|Xvnc)" | grep -v grep || echo "실행 중인 프로세스 없음"

echo ""
echo "7단계: VNC 연결 상태 확인..."
if [ -f ~/.vnc/localhost:1.log ]; then
    echo "VNC 로그 (최근 10줄):"
    tail -10 ~/.vnc/localhost:1.log
fi

echo ""
echo "=========================================="
echo "  Cursor AI 화면 표시 완료!"
echo "=========================================="
echo ""
echo "VNC 연결 정보:"
echo "  서버 주소: localhost:5901"
echo "  비밀번호: cursor123"
echo ""
echo "이제 VNC Viewer에서:"
echo "1. 연결을 새로고침하거나 재연결하세요"
echo "2. 회색 화면에서 Cursor AI 창이 나타날 것입니다"
echo "3. 만약 보이지 않으면 화면을 클릭해보세요"
echo ""
echo "문제 해결:"
echo "- VNC Viewer 앱 재시작"
echo "- 다른 VNC Viewer 앱 시도 (bVNC 등)"
echo "- ./scripts/check_cursor_status.sh 로 상태 확인"
echo ""
echo "Cursor AI 화면 표시 완료!" 