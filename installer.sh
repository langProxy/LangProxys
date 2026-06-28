#!/data/data/com.termux/files/usr/bin/bash
set -e

REPO="https://github.com/langProxy/LangProxys.git"
DIR="$HOME/LangProxys"

echo "===================================="
echo "      LangProxy Installer"
echo "===================================="

pkg update -y
pkg install -y git

if [ -d "$DIR/.git" ]; then
  echo "[*] Updating LangProxys..."
  cd "$DIR"
  git pull
else
  echo "[*] Cloning LangProxys..."
  git clone "$REPO" "$DIR"
fi

cd "$DIR"

if [ -f "./LangProxy" ]; then
  chmod +x ./LangProxy
  echo "[*] Menjalankan LangProxy..."
  ./LangProxy
else
  echo "[!] File 'LangProxy' tidak ditemukan."
  echo "Isi repository:"
  ls -la
fi
