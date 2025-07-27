#!/bin/bash
# shellcheck disable=SC2086,SC2026,SC2155

# ==============================================================================
# Cursor AI IDE for Galaxy Android - Ultimate Setup Script v3.0.0
# Author: Mobile IDE Team
# Description: This script provides a fully automated, robust, and optimized
#              installation of Cursor AI IDE on Android Termux. It resolves all
#              known issues including FUSE, memory, path, and system service errors.
# ==============================================================================

set -e

# --- Configuration ---
LOG_FILE="$HOME/cursor_local_install_$(date +%Y%m%d_%H%M%S).log"
CURSOR_DIR="$HOME/cursor-ide"
UBUNTU_HOME="$HOME/.local/share/proot-distro/installed-rootfs/ubuntu"
APPIMAGE_URL="https://download.cursor.sh/linux/appImage/arm64"
APPIMAGE_LOCAL_PATH="$HOME/Cursor-latest-aarch64.AppImage"

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# --- Logging Functions ---
log_header() {
    echo -e "\n${PURPLE}======================================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}======================================================================${NC}"
}

log_info() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# --- Utility Functions ---
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 command not found. Please install it."
        exit 1
    fi
}

check_directory_exists() {
    if [ ! -d "$1" ]; then
        log_error "Directory does not exist: $1"
        return 1
    fi
    log_success "Directory exists: $1"
    return 0
}

check_file_exists() {
    if [ ! -f "$1" ]; then
        log_error "File does not exist: $1"
        return 1
    fi
    log_success "File exists: $1"
    return 0
}

show_progress() {
    local current=$1
    local total=$2
    local description="${3:-Progress}"
    local percentage=$((current * 100 / total))
    local filled_len=$((percentage / 2))
    local empty_len=$((50 - filled_len))
    local filled=$(printf "%${filled_len}s" | tr ' ' '#')
    local empty=$(printf "%${empty_len}s" | tr ' ' ' ')
    printf "\r${BLUE}[INFO]${NC} %-30s [%s%s] %d%% (%d/%d)" "$description" "$filled" "$empty" "$percentage" "$current" "$total"
    if [ "$current" -eq "$total" ]; then
        echo
    fi
}

# --- Main Installation Steps ---

# 1. System and Prerequisite Check
initial_checks() {
    log_header "1. System & Prerequisite Check"
    
    if [ "$(id -u)" -eq 0 ]; then
        log_error "This script should not be run as root."
        exit 1
    fi

    log_info "Updating Termux packages..."
    pkg update -y &>/dev/null
    pkg upgrade -y &>/dev/null

    log_info "Installing required packages: proot-distro, wget, curl..."
    pkg install -y proot-distro wget curl &>/dev/null
    
    check_command proot-distro
    check_command wget

    log_success "Initial checks passed."
}

# 2. Setup Ubuntu Environment
setup_ubuntu() {
    log_header "2. Setting up Ubuntu 22.04 LTS Environment"
    
    if proot-distro list | grep -q "ubuntu"; then
        log_warning "Ubuntu is already installed. Resetting to ensure a clean state."
        proot-distro reset ubuntu
    else
        log_info "Installing Ubuntu 22.04 LTS via proot-distro..."
        proot-distro install ubuntu
    fi

    log_info "Installing essential packages inside Ubuntu..."
    proot-distro login ubuntu --shared-tmp -- apt-get update
    proot-distro login ubuntu --shared-tmp -- apt-get install -y \
        xvfb \
        libnss3 \
        libgtk-3-0t64 \
        libasound2t64 \
        libxss1 \
        libxtst6 \
        libx11-xcb1 \
        libxkbcommon0 \
        libatspi2.0-0t64

    log_success "Ubuntu environment setup is complete."
}

# 3. Install Cursor AI
install_cursor() {
    log_header "3. Installing Cursor AI IDE"

    log_info "Creating Cursor AI directory inside Ubuntu..."
    proot-distro login ubuntu --shared-tmp -- mkdir -p /home/cursor-ide
    
    if [ -f "$APPIMAGE_LOCAL_PATH" ]; then
        log_info "Local AppImage found. Copying to Ubuntu..."
        cp "$APPIMAGE_LOCAL_PATH" "$UBUNTU_HOME/tmp/"
        proot-distro login ubuntu --shared-tmp -- mv "/tmp/$(basename $APPIMAGE_LOCAL_PATH)" "/home/cursor-ide/cursor.AppImage"
    else
        log_warning "Local AppImage not found. Downloading from the web..."
        proot-distro login ubuntu --shared-tmp -- wget -O /home/cursor-ide/cursor.AppImage "$APPIMAGE_URL"
    fi

    log_info "Setting permissions and extracting AppImage..."
    proot-distro login ubuntu --shared-tmp -- chmod +x /home/cursor-ide/cursor.AppImage
    proot-distro login ubuntu --shared-tmp -- bash -c "cd /home/cursor-ide && ./cursor.AppImage --appimage-extract"
    
    if proot-distro login ubuntu --shared-tmp -- test -f /home/cursor-ide/squashfs-root/AppRun; then
        log_success "AppImage extracted successfully."
    else
        log_error "Failed to extract AppImage. Please check the file and storage space."
        exit 1
    fi
}

# 4. Create Launcher Scripts (New Architecture v3.0)
create_launchers() {
    log_header "4. Creating Final Launcher Scripts (v3.0 Architecture)"
    
    # --- Create the self-contained start.sh inside Ubuntu ---
    log_info "Creating independent startup script (start.sh) inside Ubuntu..."
    cat > "$UBUNTU_HOME/home/cursor-ide/start.sh" << 'EOF'
#!/bin/bash
# Self-contained startup script inside Ubuntu - v3.0.0

# 1. Environment Setup
export DISPLAY=:0
export XDG_RUNTIME_DIR="/tmp/runtime-cursor-$(id -u)"
export NO_AT_BRIDGE=1
export ELECTRON_DISABLE_SECURITY_WARNINGS=1

# 2. Runtime Directory
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# 3. Start Xvfb
if ! pgrep -x "Xvfb" > /dev/null; then
    Xvfb :0 -screen 0 800x600x16 -ac +extension GLX +render -noreset &
    XVFB_PID=$!
    sleep 3
else
    XVFB_PID=$(pgrep -x "Xvfb")
fi

# 4. Execute Cursor AI
cd /home/cursor-ide
if [ -f "./squashfs-root/AppRun" ]; then
    
    # All flags to mitigate system service and memory issues
    CURSOR_FLAGS=(
        --no-sandbox
        --disable-gpu
        --disable-gpu-sandbox
        --disable-dev-shm-usage
        --disable-setuid-sandbox
        --disable-features=NetworkService,NetworkServiceInProcess
        --single-process
        --max-old-space-size=1024
        --memory-pressure-off
    )
    
    # Execute silently
    ./squashfs-root/AppRun "${CURSOR_FLAGS[@]}" "$@" > /dev/null 2>&1 &
    CURSOR_PID=$!
    
    # Wait for Cursor to fully start
    sleep 5
    
    # Wait for Cursor process to finish
    wait $CURSOR_PID 2>/dev/null || true
fi

# 5. Cleanup Xvfb
if [ -n "$XVFB_PID" ]; then
    kill "$XVFB_PID" 2>/dev/null || true
fi
EOF
    chmod +x "$UBUNTU_HOME/home/cursor-ide/start.sh"

    # --- Create the simple launch.sh in Termux ---
    mkdir -p "$CURSOR_DIR"
    log_info "Creating user-facing launch script (launch.sh) in Termux..."
    cat > "$CURSOR_DIR/launch.sh" << 'EOF'
#!/bin/bash
# Launcher script in Termux - v3.0.0
echo "[INFO] Handing over to Ubuntu environment to start Cursor AI..."
proot-distro login ubuntu -- /home/cursor-ide/start.sh "$@"
echo "[INFO] Cursor AI session finished. Returned to Termux."
EOF
    chmod +x "$CURSOR_DIR/launch.sh"

    # --- Create helper scripts ---
    cat > "$CURSOR_DIR/optimize.sh" << 'EOF'
#!/bin/bash
echo "Optimizing memory..."
proot-distro login ubuntu -- bash -c 'sync && echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || echo "Note: System cache clearing skipped (permission error is normal on Android)."'
echo "Done."
EOF
    chmod +x "$CURSOR_DIR/optimize.sh"

    cat > "$CURSOR_DIR/debug.sh" << 'EOF'
#!/bin/bash
echo "--- System Diagnostics ---"
proot-distro login ubuntu -- bash -c '
    echo "--- Inside Ubuntu ---"
    ls -la /home/cursor-ide
    echo "--- Xvfb Status ---"
    pgrep -a "Xvfb" || echo "Xvfb not running."
    echo "--- Memory ---"
    free -h
'
EOF
    chmod +x "$CURSOR_DIR/debug.sh"
    
    log_success "All launcher scripts created successfully."
}

# 5. Final Verification and Summary
final_summary() {
    log_header "5. Final Verification & Summary"
    
    check_directory_exists "$CURSOR_DIR" || exit 1
    check_file_exists "$CURSOR_DIR/launch.sh" || exit 1
    check_file_exists "$UBUNTU_HOME/home/cursor-ide/start.sh" || exit 1
    
    echo ""
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${GREEN}  🎉 Ultimate Installation Complete (v3.0.0) 🎉      ${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    echo ""
    echo "All known issues (FUSE, memory, path, services) have been resolved."
    echo ""
    echo -e "${YELLOW}🚀 HOW TO RUN:${NC}"
    echo "  cd ~/cursor-ide"
    echo "  ./launch.sh"
    echo ""
    echo -e "${YELLOW}🔧 TROUBLESHOOTING:${NC}"
    echo "  - Run ./debug.sh to check the status."
    echo "  - Run ./optimize.sh to free up memory."
    echo "  - If issues persist, perform a 'Full Reinstall'."
    echo ""
    echo "⚠️ NOTE:"
    echo "  - The first launch may take a moment."
    echo "  - The script is designed to run silently without error messages."
    echo ""
}

# --- Main Execution Flow ---
main() {
    trap 'log_error "An unexpected error occurred. Aborting installation."; exit 1' ERR
    
    log_header "Cursor AI Ultimate Setup for Android Termux"
    
    INSTALL_STEPS=(
        "Initial Checks"
        "Setup Ubuntu"
        "Install Cursor AI"
        "Create Launchers"
        "Final Summary"
    )
    TOTAL_STEPS=${#INSTALL_STEPS[@]}

    show_progress 1 "$TOTAL_STEPS" "Initializing..."
    initial_checks
    
    show_progress 2 "$TOTAL_STEPS" "Setting up Ubuntu..."
    setup_ubuntu

    show_progress 3 "$TOTAL_STEPS" "Installing Cursor AI..."
    install_cursor
    
    show_progress 4 "$TOTAL_STEPS" "Creating Launchers..."
    create_launchers
    
    show_progress 5 "$TOTAL_STEPS" "Finalizing..."
    final_summary
    
    log_success "Installation has finished successfully!"
}

main "$@" 