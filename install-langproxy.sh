#!/usr/bin/env bash
# ================================================================
# LangProxy Installer - Created by Palang
# Universal untuk Termux & VPS
# ================================================================

set -e

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Konfigurasi
REPO_URL="https://raw.githubusercontent.com/langProxy/LangProxys/main"
PROXY_SCRIPT="LangProxy"
INSTALL_DIR="$HOME/LangProxy"
PORT=8080
GAME_PORT=17091
WEB_PORT=8081
FORCE=0

# Fungsi bantuan
usage() {
    echo "Usage: bash install-langproxy.sh [options]"
    echo "Options:"
    echo "  --port <port>     Set proxy port (default 8080)"
    echo "  --gameport <port> Set game port (default 17091)"
    echo "  --webport <port>  Set web port (default 8081)"
    echo "  --force           Force reinstall"
    echo "  --help            Show this help"
}

# Log functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERR]${NC} $1"; exit 1; }

# Deteksi OS
detect_os() {
    if [[ -d /data/data/com.termux ]]; then
        OS="termux"
        PKG_MANAGER="pkg"
        LUA_PKG="lua53"
        LUA_CMD="lua53"
        SOCKET_PKG="lua53-luasocket"
        JSON_PKG="lua53-json"
    elif command -v apt >/dev/null 2>&1; then
        OS="debian"
        PKG_MANAGER="apt"
        LUA_PKG="lua5.3"
        LUA_CMD="lua5.3"
        SOCKET_PKG="lua-socket"
        JSON_PKG="lua-json"
        SUDO="sudo"
    elif command -v yum >/dev/null 2>&1; then
        OS="rhel"
        PKG_MANAGER="yum"
        LUA_PKG="lua"
        LUA_CMD="lua"
        SOCKET_PKG="lua-socket"
        JSON_PKG="lua-json"
        SUDO="sudo"
    else
        log_err "Unsupported OS. Please install Lua 5.3 and luasocket manually."
    fi
    log_info "Detected OS: $OS"
}

# Install dependencies
install_deps() {
    log_info "Installing dependencies using $PKG_MANAGER..."
    case "$OS" in
        termux)
            $PKG_MANAGER update -y
            $PKG_MANAGER install -y $LUA_PKG $SOCKET_PKG $JSON_PKG wget curl
            ;;
        debian)
            $SUDO $PKG_MANAGER update -y
            $SUDO $PKG_MANAGER install -y $LUA_PKG $SOCKET_PKG $JSON_PKG wget curl
            ;;
        rhel)
            $SUDO $PKG_MANAGER install -y $LUA_PKG $SOCKET_PKG $JSON_PKG wget curl
            ;;
    esac
    log_ok "Dependencies installed."
}

# Download proxy script
download_proxy() {
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    log_info "Downloading LangProxy from $REPO_URL/$PROXY_SCRIPT"
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$PROXY_SCRIPT" "$REPO_URL/$PROXY_SCRIPT" || {
            log_err "Failed to download using wget. Check internet or URL."
        }
    elif command -v curl >/dev/null 2>&1; then
        curl -s -o "$PROXY_SCRIPT" "$REPO_URL/$PROXY_SCRIPT" || {
            log_err "Failed to download using curl. Check internet or URL."
        }
    else
        log_err "Neither wget nor curl found. Please install one."
    fi

    if [[ ! -f "$PROXY_SCRIPT" ]]; then
        log_err "Proxy script not found after download."
    fi

    chmod +x "$PROXY_SCRIPT"
    log_ok "Proxy script downloaded to $INSTALL_DIR/$PROXY_SCRIPT"
}

# Configure ports
configure_ports() {
    if [[ -f "$INSTALL_DIR/$PROXY_SCRIPT" ]]; then
        sed -i "s/proxy_port = [0-9]\+/proxy_port = $PORT/g" "$INSTALL_DIR/$PROXY_SCRIPT"
        sed -i "s/game_port = [0-9]\+/game_port = $GAME_PORT/g" "$INSTALL_DIR/$PROXY_SCRIPT"
        sed -i "s/web_port = [0-9]\+/web_port = $WEB_PORT/g" "$INSTALL_DIR/$PROXY_SCRIPT"
        log_ok "Ports configured: proxy=$PORT, game=$GAME_PORT, web=$WEB_PORT"
    fi
}

# Create systemd service (only for VPS)
create_service() {
    if [[ "$OS" != "termux" ]] && command -v systemctl >/dev/null 2>&1; then
        log_info "Creating systemd service..."
        $SUDO tee /etc/systemd/system/langproxy.service > /dev/null <<EOF
[Unit]
Description=LangProxy - Growtopia Proxy
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/$LUA_CMD $INSTALL_DIR/$PROXY_SCRIPT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable langproxy
        log_ok "Service created. Start with: sudo systemctl start langproxy"
    fi
}

# Main
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --port) shift; PORT="$1" ;;
            --gameport) shift; GAME_PORT="$1" ;;
            --webport) shift; WEB_PORT="$1" ;;
            --force) FORCE=1 ;;
            --help) usage; exit 0 ;;
            *) log_err "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done

    echo ""
    echo -e "${GREEN}===== LangProxy Installer =====${NC}"
    echo "Created by Palang"
    echo ""

    detect_os
    install_deps
    download_proxy
    configure_ports

    if [[ "$OS" != "termux" ]]; then
        create_service
    fi

    echo ""
    log_ok "LangProxy installed successfully!"
    echo ""
    echo "To run manually:"
    echo "  cd $INSTALL_DIR && $LUA_CMD $PROXY_SCRIPT"
    echo ""
    echo "Connect to Growtopia using:"
    echo "  IP: localhost (or your VPS IP)"
    echo "  Port: $PORT"
    echo ""
    echo "Web interface: http://localhost:$WEB_PORT"
    echo ""
    echo "Commands in-game: /help"
    echo ""
    echo "Created by Palang - Enjoy!"
}

main "$@"