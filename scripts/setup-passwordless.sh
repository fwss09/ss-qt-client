#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULE_SRC="$SCRIPT_DIR/50-ssclient-vpn.rules"
DEST="/etc/polkit-1/rules.d/50-ssclient-vpn.rules"

echo "[*] Installing Polkit rule to allow 1-click VPN without password..."
sudo cp "$RULE_SRC" "$DEST"
sudo chmod 644 "$DEST"

# Sudoers fallback
echo "%wheel ALL=(ALL) NOPASSWD: $SCRIPT_DIR/vpn-route.sh" | sudo tee /etc/sudoers.d/ssclient-vpn > /dev/null
sudo chmod 440 /etc/sudoers.d/ssclient-vpn

echo "[✓] Done! VPN will now connect instantly without password prompts."
