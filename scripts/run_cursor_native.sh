#!/bin/bash

echo "=========================================="
echo "  Cursor AI 네이티브 실행 (proot 우회)"
echo "=========================================="

echo "1단계: 기존 프로세스 정리..."
ps aux | grep -E "(cursor|AppRun)" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || echo "기존 프로세스 없음"
vncserver -kill :1 2>/dev/null || echo "VNC 서버 없음"
sleep 2

echo ""
echo "2단계: VNC 서버 시작..."
vncserver :1 -geometry 1024x768 -depth 24 -localhost no -SecurityTypes VncAuth -dpi 96 &
sleep 5

echo ""
echo "3단계: X11 환경 설정..."
export DISPLAY=:1
export XDG_RUNTIME_DIR="$HOME/.runtime-cursor"
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=X-Generic
export NO_AT_BRIDGE=1
export ELECTRON_DISABLE_SECURITY_WARNINGS=true
export LIBGL_ALWAYS_SOFTWARE=1
export QT_X11_NO_MITSHM=1

# 런타임 디렉토리 생성
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo ""
echo "4단계: X11 연결 테스트..."
xset q 2>/dev/null && echo "X11 연결 성공" || echo "X11 연결 실패"

echo ""
echo "5단계: Cursor AI 네이티브 실행..."

# 현재 디렉토리에서 AppImage 실행
cd ~/mobile_ide

# AppImage가 실행 가능한지 확인
if [ ! -x "./Cursor-1.2.1-aarch64.AppImage" ]; then
    echo "AppImage 실행 권한 설정 중..."
    chmod +x ./Cursor-1.2.1-aarch64.AppImage
fi

echo "Cursor AI 실행 중 (네이티브 모드)..."
nohup ./Cursor-1.2.1-aarch64.AppImage \
  --no-sandbox \
  --disable-gpu \
  --disable-software-rasterizer \
  --disable-gpu-sandbox \
  --single-process \
  --disable-dev-shm-usage \
  --disable-background-timer-throttling \
  --disable-renderer-backgrounding \
  --disable-backgrounding-occluded-windows \
  --disable-features=TranslateUI,VizDisplayCompositor,AudioServiceOutOfProcess \
  --disable-ipc-flooding-protection \
  --disable-web-security \
  --max-old-space-size=512 \
  --js-flags='--max-old-space-size=512' \
  --no-first-run \
  --no-default-browser-check \
  --disable-default-apps \
  --disable-extensions \
  --disable-plugins \
  --disable-sync \
  --disable-translate \
  --disable-background-networking \
  --disable-component-extensions-with-background-pages \
  --disable-breakpad \
  --disable-client-side-phishing-detection \
  --disable-component-update \
  --disable-datasaver-prompt \
  --disable-domain-reliability \
  --disable-hang-monitor \
  --disable-prompt-on-repost \
  --disable-logging \
  --disable-login-animations \
  --disable-new-bookmark-apps \
  --disable-office-editing-component-app \
  --disable-password-generation \
  --disable-pdf-extension \
  --disable-permissions-api \
  --disable-plugins-discovery \
  --disable-prerender-local-predictor \
  --disable-print-preview \
  --disable-voice-input \
  --force-device-scale-factor=1 \
  --high-dpi-support=0 \
  --enable-features=UseOzonePlatform \
  --ozone-platform=x11 \
  --use-gl=swiftshader \
  --ignore-gpu-blacklist \
  --ignore-gpu-blocklist > /tmp/cursor_native.log 2>&1 &

CURSOR_PID=$!
echo "Cursor AI 시작됨 (PID: $CURSOR_PID)"

echo ""
echo "6단계: 프로세스 상태 확인..."
sleep 8

if kill -0 $CURSOR_PID 2>/dev/null; then
    echo "✅ Cursor AI 실행 중 확인됨"
    ps aux | grep -E "(cursor|AppRun)" | grep -v grep
else
    echo "❌ Cursor AI 프로세스 종료됨"
    echo "로그 확인:"
    tail -10 /tmp/cursor_native.log 2>/dev/null || echo "로그 파일 없음"
fi

echo ""
echo "7단계: 최종 상태 확인..."
echo "실행 중인 프로세스:"
ps aux | grep -E "(cursor|AppRun|Xvnc)" | grep -v grep || echo "실행 중인 프로세스 없음"

echo ""
echo "=========================================="
echo "  Cursor AI 네이티브 실행 완료!"
echo "=========================================="
echo ""
echo "VNC 연결 정보:"
echo "  서버 주소: localhost:5901"
echo "  비밀번호: cursor123"
echo ""
echo "이제 VNC Viewer에서 접속하여 Cursor AI 화면을 확인하세요."
echo ""
echo "문제 해결:"
echo "1. VNC Viewer 앱 재시작"
echo "2. 다른 VNC 앱 시도 (bVNC, aRDP 등)"
echo "3. 로그 확인: tail -f /tmp/cursor_native.log"
echo "4. 프로세스 확인: ps aux | grep cursor"
echo ""
echo "네이티브 실행 완료!" 