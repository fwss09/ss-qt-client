#!/usr/bin/env bash
set -e

VERSION="1.0.0"
DIST_DIR="skugg-${VERSION}-linux-x86_64"

echo "==> Creating portable distribution package: ${DIST_DIR}"
rm -rf "${DIST_DIR}" "${DIST_DIR}.tar.gz"
mkdir -p "${DIST_DIR}/bin" "${DIST_DIR}/scripts"

# Copy binaries
cp bin/ssclient "${DIST_DIR}/bin/skugg"
if [ -f bin/tun2socks ]; then
  cp bin/tun2socks "${DIST_DIR}/bin/tun2socks"
fi

# Copy scripts and assets
cp -r scripts/* "${DIST_DIR}/scripts/" 2>/dev/null || true
cp skugg.desktop "${DIST_DIR}/"
cp skugg.svg "${DIST_DIR}/"
cp LICENSE "${DIST_DIR}/"
cp README.md "${DIST_DIR}/"

# Create easy launch script
cat << 'EOF' > "${DIST_DIR}/skugg.sh"
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="${SCRIPT_DIR}/bin:${PATH}"
exec "${SCRIPT_DIR}/bin/skugg" "$@"
EOF
chmod +x "${DIST_DIR}/skugg.sh"

# Create quick install script (optional for users)
cat << 'EOF' > "${DIST_DIR}/install.sh"
#!/usr/bin/env bash
set -e
echo "Installing skugg for current user..."
mkdir -p ~/.local/bin ~/.local/share/applications ~/.local/share/icons/hicolor/scalable/apps
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "${SCRIPT_DIR}/bin/skugg" ~/.local/bin/skugg
if [ -f "${SCRIPT_DIR}/bin/tun2socks" ]; then
  cp "${SCRIPT_DIR}/bin/tun2socks" ~/.local/bin/tun2socks
fi
cp "${SCRIPT_DIR}/skugg.svg" ~/.local/share/icons/hicolor/scalable/apps/skugg.svg

sed "s|Exec=ssclient|Exec=${HOME}/.local/bin/skugg|g" "${SCRIPT_DIR}/skugg.desktop" > ~/.local/share/applications/skugg.desktop
chmod +x ~/.local/share/applications/skugg.desktop

echo "Installed successfully! You can launch 'skugg' from terminal or application menu."
EOF
chmod +x "${DIST_DIR}/install.sh"

# Create tar.gz
tar -czvf "${DIST_DIR}.tar.gz" "${DIST_DIR}"

echo "==> Release archive created successfully: ${DIST_DIR}.tar.gz"
ls -lh "${DIST_DIR}.tar.gz"
