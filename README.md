# Galaxy Android용 Cursor AI IDE 실행 환경

Samsung Galaxy Android 기기에서 Cursor AI IDE를 실행하기 위한 완전한 솔루션입니다.

## 🚀 주요 기능

- **Termux 기반 Linux 환경**: Ubuntu/Debian 환경에서 Cursor AI 실행
- **모바일 최적화**: 터치 인터페이스, 가상 키보드 지원
- **자동 설치**: 한 번의 명령으로 전체 환경 구축
- **성능 최적화**: 메모리 및 배터리 효율성 고려

## 📱 지원 기기

- Samsung Galaxy 시리즈 (Android 7.0+)
- ARM64 아키텍처
- 최소 4GB RAM 권장
- 최소 10GB 저장공간

## 🛠️ 설치 방법

### 1단계: Termux 설치
1. F-Droid에서 Termux 설치
2. Termux 실행 후 다음 명령어 실행:

```bash
curl -sSL https://raw.githubusercontent.com/your-repo/mobile_ide/main/scripts/setup.sh | bash
```

### 2단계: Cursor AI 실행
```bash
./launch.sh
```

## 📁 프로젝트 구조

```
mobile_ide/
├── scripts/
│   ├── setup.sh          # 초기 설치 스크립트
│   ├── launch.sh         # Cursor AI 실행 스크립트
│   ├── restore.sh        # 환경 복구 스크립트
│   └── optimize.sh       # 성능 최적화 스크립트
├── config/
│   ├── cursor-config.json # Cursor AI 설정
│   ├── termux-config.sh   # Termux 환경 설정
│   └── x11-config.sh      # X11 서버 설정
├── docs/
│   ├── installation.md    # 상세 설치 가이드
│   ├── troubleshooting.md # 문제 해결 가이드
│   └── optimization.md    # 성능 최적화 가이드
└── tests/
    └── compatibility.sh   # 호환성 테스트
```

## 🔧 주요 컴포넌트

### Termux 환경
- **proot-distro**: Ubuntu 22.04 LTS 환경
- **X11 서버**: VNC 또는 Xvfb 기반 GUI
- **필수 패키지**: Node.js, npm, git, curl, wget

### Cursor AI 설정
- **ARM64 호환성**: AppImage 또는 .deb 패키지
- **모바일 UI**: 터치 친화적 인터페이스
- **성능 최적화**: 메모리 및 CPU 사용량 최적화

## 📊 성능 지표

- **시작 시간**: ~30초 (첫 실행), ~10초 (재실행)
- **메모리 사용량**: ~2-4GB (기본 설정)
- **배터리 소모**: 일반적인 모바일 앱 수준
- **저장공간**: ~5GB (Cursor AI + Linux 환경)

## 🐛 문제 해결

자주 발생하는 문제와 해결 방법은 [troubleshooting.md](docs/troubleshooting.md)를 참조하세요.

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🙏 감사의 말

- [Termux](https://termux.com/) - Android용 Linux 터미널
- [Cursor AI](https://cursor.sh/) - AI 기반 코드 에디터
- [proot-distro](https://github.com/termux/proot-distro) - Linux 배포판 실행 환경

---

**⚠️ 주의사항**: 이 프로젝트는 개발 및 테스트 목적으로 제작되었습니다. 프로덕션 환경에서 사용하기 전에 충분한 테스트를 진행하세요. 