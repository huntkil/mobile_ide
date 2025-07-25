#!/bin/bash

# Galaxy Android용 Cursor AI IDE 성능 최적화 스크립트
# Author: Mobile IDE Team
# Version: 1.0.0

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 시스템 정보 출력
print_system_info() {
    log_info "시스템 정보:"
    echo "  CPU: $(nproc) 코어"
    echo "  메모리: $(free -h | grep Mem | awk '{print $2}')"
    echo "  사용 가능한 메모리: $(free -h | grep Mem | awk '{print $7}')"
    echo "  저장공간: $(df -h /data | tail -1 | awk '{print $4}') 사용 가능"
    echo "  Android 버전: $(getprop ro.build.version.release)"
    echo "  아키텍처: $(uname -m)"
}

# 메모리 최적화
optimize_memory() {
    log_info "메모리 최적화 중..."
    
    # 메모리 캐시 정리
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || {
        log_warning "메모리 캐시 정리 권한이 없습니다."
    }
    
    # 스왑 사용량 확인
    local swap_usage=$(free | grep Swap | awk '{print $3}')
    if [ "$swap_usage" -gt 0 ]; then
        log_info "스왑 사용량: ${swap_usage}KB"
        log_info "스왑 정리 중..."
        swapoff -a 2>/dev/null && swapon -a 2>/dev/null || {
            log_warning "스왑 정리 권한이 없습니다."
        }
    fi
    
    # 불필요한 프로세스 종료
    log_info "불필요한 프로세스 정리 중..."
    pkill -f "Xvfb" 2>/dev/null || true
    
    log_success "메모리 최적화 완료"
}

# CPU 최적화
optimize_cpu() {
    log_info "CPU 최적화 중..."
    
    # CPU 성능 모드 설정
    local cpu_count=$(nproc)
    for ((i=0; i<cpu_count; i++)); do
        echo performance > "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor" 2>/dev/null || {
            log_warning "CPU ${i} 성능 모드 설정 권한이 없습니다."
        }
    done
    
    # CPU 주파수 확인
    local current_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo "N/A")
    log_info "현재 CPU 주파수: ${current_freq}kHz"
    
    log_success "CPU 최적화 완료"
}

# 배터리 최적화 비활성화
disable_battery_optimization() {
    log_info "배터리 최적화 비활성화 중..."
    
    # Termux 배터리 최적화 비활성화
    dumpsys deviceidle disable 2>/dev/null || {
        log_warning "배터리 최적화 비활성화 권한이 없습니다."
    }
    
    # Doze 모드 비활성화
    dumpsys deviceidle whitelist +com.termux 2>/dev/null || {
        log_warning "Doze 모드 비활성화 권한이 없습니다."
    }
    
    log_success "배터리 최적화 비활성화 완료"
}

# 네트워크 최적화
optimize_network() {
    log_info "네트워크 최적화 중..."
    
    # DNS 캐시 정리
    nscd -i hosts 2>/dev/null || {
        log_info "DNS 캐시 정리 (nscd 없음)"
    }
    
    # 네트워크 버퍼 크기 최적화
    echo 1048576 > /proc/sys/net/core/rmem_max 2>/dev/null || {
        log_warning "네트워크 버퍼 최적화 권한이 없습니다."
    }
    echo 1048576 > /proc/sys/net/core/wmem_max 2>/dev/null || {
        log_warning "네트워크 버퍼 최적화 권한이 없습니다."
    }
    
    log_success "네트워크 최적화 완료"
}

# Ubuntu 환경 최적화
optimize_ubuntu_environment() {
    log_info "Ubuntu 환경 최적화 중..."
    
    if [ ! -d "$HOME/ubuntu" ]; then
        log_warning "Ubuntu 환경이 설치되지 않았습니다."
        return
    fi
    
    # Ubuntu 환경에서 최적화 스크립트 실행
    cat > "$HOME/optimize_ubuntu.sh" << 'EOF'
#!/bin/bash
set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Ubuntu 환경 최적화 시작..."

# 패키지 캐시 정리
apt clean
apt autoremove -y

# npm 캐시 정리
npm cache clean --force

# 시스템 로그 정리
journalctl --vacuum-time=1d 2>/dev/null || true

# 임시 파일 정리
rm -rf /tmp/* 2>/dev/null || true

# 메모리 최적화 설정
echo 'vm.swappiness=10' >> /etc/sysctl.conf 2>/dev/null || true

# 파일 시스템 최적화
echo 'noatime' >> /etc/fstab 2>/dev/null || true

echo -e "${GREEN}[SUCCESS]${NC} Ubuntu 환경 최적화 완료!"
EOF

    proot-distro login ubuntu -- bash "$HOME/optimize_ubuntu.sh"
    rm "$HOME/optimize_ubuntu.sh"
}

# Cursor AI 설정 최적화
optimize_cursor_settings() {
    log_info "Cursor AI 설정 최적화 중..."
    
    # 최적화된 설정 파일 생성
    cat > "$HOME/cursor-optimized-config.json" << 'EOF'
{
    "window": {
        "width": 1200,
        "height": 800,
        "minWidth": 800,
        "minHeight": 600,
        "resizable": true,
        "maximizable": true,
        "fullscreenable": true,
        "zoomLevel": 0
    },
    "editor": {
        "fontSize": 14,
        "fontFamily": "Monaco, 'Courier New', monospace",
        "lineHeight": 1.5,
        "wordWrap": "on",
        "minimap": {
            "enabled": false
        },
        "scrollBeyondLastLine": false,
        "smoothScrolling": true,
        "cursorBlinking": "smooth",
        "cursorSmoothCaretAnimation": "on",
        "renderWhitespace": "none",
        "renderControlCharacters": false,
        "renderLineHighlight": "line",
        "folding": true,
        "foldingStrategy": "auto",
        "showFoldingControls": "mouseover",
        "unfoldOnClickAfterEnd": false,
        "links": false,
        "colorDecorators": false,
        "lightbulb": {
            "enabled": false
        },
        "codeActionsOnSave": {},
        "formatOnSave": false,
        "formatOnPaste": false,
        "formatOnType": false,
        "suggestOnTriggerCharacters": false,
        "acceptSuggestionOnCommitCharacter": false,
        "acceptSuggestionOnEnter": "on",
        "tabCompletion": "off",
        "wordBasedSuggestions": false,
        "parameterHints": {
            "enabled": false
        },
        "autoIndent": "full",
        "detectIndentation": false,
        "insertSpaces": true,
        "tabSize": 2,
        "useTabStops": false,
        "trimAutoWhitespace": true,
        "largeFileOptimizations": true,
        "maxTokenizationLineLength": 20000,
        "maxTokenizationLineLength": 20000,
        "semanticValidation": false,
        "bracketPairColorization": {
            "enabled": false
        },
        "guides": {
            "bracketPairs": false,
            "indentation": false,
            "highlightActiveIndentation": false
        }
    },
    "workbench": {
        "colorTheme": "Default Dark+",
        "iconTheme": "vs-seti",
        "sideBar": {
            "location": "left",
            "visible": true
        },
        "panel": {
            "defaultLocation": "bottom",
            "visible": false
        },
        "tree": {
            "indent": 20,
            "renderIndentGuides": "none"
        },
        "editor": {
            "showTabs": "singleClick",
            "tabSizing": "shrink",
            "tabCloseButton": "right",
            "tabSizingFixedMinWidth": 100,
            "tabSizingFixedMaxWidth": 200
        },
        "activityBar": {
            "visible": false
        },
        "statusBar": {
            "visible": true
        },
        "menuBar": {
            "visible": false
        },
        "toolbar": {
            "visible": false
        },
        "breadcrumbs": {
            "enabled": false
        },
        "editor": {
            "showTabs": "singleClick",
            "tabSizing": "shrink",
            "tabCloseButton": "right"
        }
    },
    "terminal": {
        "integrated": {
            "fontSize": 12,
            "fontFamily": "Monaco, 'Courier New', monospace",
            "lineHeight": 1.2,
            "cursorBlinking": true,
            "cursorStyle": "line",
            "scrollback": 1000,
            "fastScrollSensitivity": 5,
            "mouseWheelScrollSensitivity": 1
        }
    },
    "files": {
        "autoSave": "afterDelay",
        "autoSaveDelay": 2000,
        "exclude": {
            "**/node_modules": true,
            "**/dist": true,
            "**/build": true,
            "**/.git": true,
            "**/.vscode": true,
            "**/coverage": true,
            "**/.nyc_output": true,
            "**/.cache": true,
            "**/tmp": true,
            "**/temp": true
        },
        "watcherExclude": {
            "**/node_modules/**": true,
            "**/dist/**": true,
            "**/build/**": true,
            "**/.git/**": true
        },
        "useExperimentalFileWatcher": false,
        "associations": {},
        "encoding": "utf8",
        "eol": "\n",
        "trimTrailingWhitespace": true,
        "insertFinalNewline": true,
        "trimFinalNewlines": true
    },
    "search": {
        "exclude": {
            "**/node_modules": true,
            "**/dist": true,
            "**/build": true,
            "**/.git": true
        },
        "useGlobalIgnoreFiles": false,
        "useParentIgnoreFiles": false,
        "useIgnoreFiles": false,
        "quickOpen": {
            "includeSymbols": false
        }
    },
    "telemetry": {
        "enableCrashReporter": false,
        "enableTelemetry": false
    },
    "update": {
        "mode": "none"
    },
    "extensions": {
        "autoUpdate": false,
        "autoCheckUpdates": false,
        "ignoreRecommendations": true
    },
    "security": {
        "workspace": {
            "trust": {
                "enabled": false
            }
        }
    },
    "http": {
        "proxySupport": "off"
    },
    "git": {
        "enabled": false,
        "autorefresh": false,
        "autofetch": false,
        "confirmSync": false,
        "enableSmartCommit": false,
        "enableCommitSigning": false,
        "showPushSuccessNotification": false,
        "showProgress": false
    },
    "scm": {
        "alwaysShowRepositories": false
    },
    "debug": {
        "console": {
            "closeOnEnd": true
        },
        "internalConsoleOptions": "neverOpen"
    },
    "typescript": {
        "suggest": {
            "enabled": false
        },
        "validate": {
            "enable": false
        }
    },
    "javascript": {
        "suggest": {
            "enabled": false
        },
        "validate": {
            "enable": false
        }
    },
    "emmet": {
        "showExpandedAbbreviation": "never",
        "showAbbreviationSuggestions": false
    },
    "css": {
        "validate": false
    },
    "html": {
        "validate": {
            "scripts": false,
            "styles": false
        }
    },
    "json": {
        "validate": {
            "enable": false
        }
    }
}
EOF

    # Ubuntu 환경으로 설정 파일 복사
    if [ -d "$HOME/ubuntu/home/cursor-ide" ]; then
        cp "$HOME/cursor-optimized-config.json" "$HOME/ubuntu/home/cursor-ide/cursor-config.json"
        log_success "Cursor AI 최적화 설정 적용 완료"
    else
        log_warning "Ubuntu 환경을 찾을 수 없습니다."
    fi
}

# 성능 모니터링
monitor_performance() {
    log_info "성능 모니터링 정보:"
    
    echo "  CPU 사용률: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "  메모리 사용률: $(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')%"
    echo "  사용 가능한 메모리: $(free -h | grep Mem | awk '{print $7}')"
    echo "  디스크 사용률: $(df -h /data | tail -1 | awk '{print $5}')"
    
    # 프로세스별 메모리 사용량 (상위 5개)
    echo ""
    echo "  메모리 사용량 상위 프로세스:"
    ps aux --sort=-%mem | head -6 | awk '{print $2, $3, $4, $11}' | column -t
}

# 메인 최적화 함수
main() {
    echo "=========================================="
    echo "  Cursor AI IDE 성능 최적화"
    echo "=========================================="
    echo ""
    
    # 시스템 정보 출력
    print_system_info
    echo ""
    
    # 메모리 최적화
    optimize_memory
    echo ""
    
    # CPU 최적화
    optimize_cpu
    echo ""
    
    # 배터리 최적화 비활성화
    disable_battery_optimization
    echo ""
    
    # 네트워크 최적화
    optimize_network
    echo ""
    
    # Ubuntu 환경 최적화
    optimize_ubuntu_environment
    echo ""
    
    # Cursor AI 설정 최적화
    optimize_cursor_settings
    echo ""
    
    # 성능 모니터링
    monitor_performance
    echo ""
    
    log_success "성능 최적화가 완료되었습니다!"
    echo ""
    echo "최적화 내용:"
    echo "  ✓ 메모리 캐시 정리"
    echo "  ✓ CPU 성능 모드 설정"
    echo "  ✓ 배터리 최적화 비활성화"
    echo "  ✓ 네트워크 버퍼 최적화"
    echo "  ✓ Ubuntu 환경 정리"
    echo "  ✓ Cursor AI 설정 최적화"
    echo ""
    echo "주의사항:"
    echo "  - 배터리 사용량이 증가할 수 있습니다."
    echo "  - 일부 최적화는 재부팅 후 적용됩니다."
    echo "  - 정기적으로 최적화를 실행하는 것을 권장합니다."
}

# 스크립트 실행
main "$@" 