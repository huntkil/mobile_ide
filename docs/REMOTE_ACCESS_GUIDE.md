# Android Termux 원격 접속 완전 가이드

## 🌐 **개요**

이 가이드는 Android Termux 환경에서 SSH와 VNC를 통한 원격 접속을 설정하고 사용하는 방법을 설명합니다.

## 🚀 **빠른 시작**

### **1단계: 원격 접속 설정**

```bash
# 프로젝트 다운로드
cd ~
git clone https://github.com/huntkil/mobile_ide.git
cd mobile_ide

# 원격 접속 관리 스크립트 실행
chmod +x scripts/remote_access_manager.sh
./scripts/remote_access_manager.sh
```

### **2단계: 통합 원격 접속 설정**

메뉴에서 **3번**을 선택하여 SSH와 VNC 서버를 모두 설정합니다.

### **3단계: 연결 정보 확인**

메뉴에서 **6번**을 선택하여 연결 정보를 확인합니다.

## 📱 **SSH 원격 접속**

### **SSH 서버 설정**

```bash
# SSH 서버만 설정
chmod +x scripts/setup_remote_access.sh
./scripts/setup_remote_access.sh
```

### **SSH 연결 방법**

#### **PC에서 연결**
```bash
# Windows (PowerShell/CMD)
ssh -p 8022 username@192.168.1.100

# macOS/Linux
ssh -p 8022 username@192.168.1.100
```

#### **모바일에서 연결**
- **Android**: Termius, ConnectBot
- **iOS**: Termius, iTerminal

### **SSH 키 설정**

```bash
# SSH 키 생성
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# 공개키 복사
cat ~/.ssh/id_rsa.pub
```

## 🖥️ **VNC 원격 접속**

### **VNC 서버 설정**

```bash
# VNC 서버만 설정
chmod +x scripts/setup_vnc_remote.sh
./scripts/setup_vnc_remote.sh
```

### **VNC 연결 방법**

#### **PC에서 연결**
- **Windows**: RealVNC Viewer, TightVNC Viewer
- **macOS**: Screen Sharing (내장)
- **Linux**: Remmina, Vinagre

#### **모바일에서 연결**
- **Android**: VNC Viewer (Google Play)
- **iOS**: VNC Viewer (App Store)

### **VNC 연결 정보**
- **주소**: `192.168.1.100:5901`
- **비밀번호**: `mobile_ide_vnc`

## 🔧 **통합 원격 접속 관리**

### **원격 접속 관리 스크립트 사용**

```bash
# 관리 스크립트 실행
./scripts/remote_access_manager.sh
```

#### **메뉴 옵션**
1. **SSH 서버 설정 및 시작** - SSH 서버만 설정
2. **VNC 서버 설정 및 시작** - VNC 서버만 설정
3. **통합 원격 접속 설정** - SSH + VNC 모두 설정
4. **서버 상태 확인** - 현재 실행 중인 서버 확인
5. **서버 중지** - 모든 서버 중지
6. **연결 정보 표시** - 연결 정보 확인
7. **원격 접속 테스트** - 연결 테스트
8. **시스템 정보 확인** - 시스템 정보 표시
9. **자동 시작 스크립트 생성** - 자동 시작 스크립트 생성

### **자동 시작 스크립트**

```bash
# 자동 시작 스크립트 생성 후
./start_remote_access.sh
```

## 📊 **연결 정보 확인**

### **시스템 정보**
```bash
# IP 주소 확인
hostname -I

# 포트 확인
netstat -tlnp | grep -E ":(8022|5901)"
```

### **서버 상태 확인**
```bash
# SSH 서버 상태
pgrep sshd

# VNC 서버 상태
pgrep vncserver
```

## 🔒 **보안 설정**

### **SSH 보안**
```bash
# SSH 키 기반 인증 설정
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### **VNC 보안**
```bash
# VNC 비밀번호 변경
vncpasswd
```

### **방화벽 설정**
```bash
# SSH 포트 열기 (선택사항)
iptables -A INPUT -p tcp --dport 8022 -j ACCEPT

# VNC 포트 열기 (선택사항)
iptables -A INPUT -p tcp --dport 5901 -j ACCEPT
```

## 🛠️ **문제 해결**

### **SSH 연결 문제**

#### **연결 거부**
```bash
# SSH 서버 상태 확인
pgrep sshd

# SSH 서버 재시작
pkill sshd
sshd -p 8022 -D &
```

#### **키 인증 실패**
```bash
# SSH 키 권한 확인
ls -la ~/.ssh/
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/authorized_keys
```

### **VNC 연결 문제**

#### **검은 화면**
```bash
# VNC 서버 재시작
pkill vncserver
vncserver :1 -geometry 1024x768 -depth 24 -localhost no
```

#### **연결 실패**
```bash
# VNC 포트 확인
netstat -tlnp | grep 5901

# VNC 서버 상태 확인
pgrep vncserver
```

### **포트 문제**

#### **포트가 열리지 않음**
```bash
# 포트 사용 중인 프로세스 확인
lsof -i :8022
lsof -i :5901

# 프로세스 종료
kill -9 [PID]
```

## 📱 **클라이언트 프로그램**

### **SSH 클라이언트**

#### **PC용**
- **Windows**: PuTTY, OpenSSH, MobaXterm
- **macOS**: Terminal (내장), iTerm2
- **Linux**: Terminal (내장), Konsole

#### **모바일용**
- **Android**: Termius, ConnectBot, JuiceSSH
- **iOS**: Termius, iTerminal, Prompt

### **VNC 클라이언트**

#### **PC용**
- **Windows**: RealVNC Viewer, TightVNC Viewer, UltraVNC
- **macOS**: Screen Sharing (내장), RealVNC Viewer
- **Linux**: Remmina, Vinagre, RealVNC Viewer

#### **모바일용**
- **Android**: VNC Viewer, RealVNC Viewer
- **iOS**: VNC Viewer, RealVNC Viewer

## 🔄 **자동화**

### **부팅 시 자동 시작**

```bash
# 자동 시작 스크립트 생성
./scripts/remote_access_manager.sh
# 메뉴에서 9번 선택

# 부팅 시 자동 실행 설정
echo "~/start_remote_access.sh" >> ~/.bashrc
```

### **서비스 관리**

```bash
# 서비스 시작
./start_remote_access.sh

# 서비스 중지
pkill sshd && pkill vncserver

# 서비스 상태 확인
pgrep sshd && pgrep vncserver
```

## 📈 **성능 최적화**

### **SSH 최적화**
```bash
# SSH 설정 최적화
cat >> ~/.ssh/config << 'EOF'
Host *
    Compression yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
```

### **VNC 최적화**
```bash
# VNC 품질 설정
vncserver :1 -geometry 1024x768 -depth 16 -localhost no
```

## 🔍 **모니터링**

### **로그 확인**
```bash
# SSH 로그
tail -f /var/log/auth.log

# VNC 로그
tail -f ~/.vnc/*.log
```

### **리소스 모니터링**
```bash
# CPU 사용량
top

# 메모리 사용량
free -h

# 네트워크 사용량
netstat -i
```

## 📞 **지원**

### **문제 보고**
- **GitHub Issues**: [프로젝트 이슈 페이지](https://github.com/huntkil/mobile_ide/issues)
- **이메일**: huntkil@github.com

### **커뮤니티**
- **Discord**: [Mobile IDE Community](https://discord.gg/mobile-ide)
- **Reddit**: r/mobile_ide

## 🎯 **결론**

이 가이드를 따라하면 Android Termux 환경에서 완전한 원격 접속 시스템을 구축할 수 있습니다. SSH를 통한 명령줄 접속과 VNC를 통한 GUI 접속을 모두 사용할 수 있어, 모바일 기기를 완전한 개발 서버로 활용할 수 있습니다.

---

**🔄 최신 업데이트**: v1.0.0 (2025-07-27) - 원격 접속 시스템 완성!  
**📊 지원**: SSH + VNC 통합 원격 접속  
**🎯 목표**: 모바일 기기를 완전한 개발 서버로 활용 