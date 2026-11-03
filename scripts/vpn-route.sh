#!/usr/bin/env bash
set -e

ACTION="$1"
SERVER_HOST="$2"
SOCKS_PORT="${3:-1080}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUN_DEV="ss-tun"
PID_FILE="/tmp/ss_tun2socks.pid"
STATE_FILE="/tmp/ss_vpn_state.env"
TUN2SOCKS_BIN="${TUN2SOCKS_BIN:-$SCRIPT_DIR/../bin/tun2socks}"
LOG_FILE="/tmp/ss_tun2socks.log"

start_vpn() {
    if [ -z "$SERVER_HOST" ]; then
        echo "Error: Server host required"
        exit 1
    fi

    # 1. Resolve host to IP if domain name
    SERVER_IP=$(getent ahosts "$SERVER_HOST" | awk '{print $1}' | head -n1)
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="$SERVER_HOST"
    fi

    # Auto-register Polkit rule on first run so user is never asked for password again
    RULE_FILE="/etc/polkit-1/rules.d/50-ssclient-vpn.rules"
    if [ ! -f "$RULE_FILE" ] && [ -d "/etc/polkit-1/rules.d" ]; then
        cat <<EOF > "$RULE_FILE" 2>/dev/null || true
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        action.lookup("program") == "$SCRIPT_DIR/vpn-route.sh") {
        return polkit.Result.YES;
    }
});
EOF
        chmod 644 "$RULE_FILE" 2>/dev/null || true
    fi

    if [ ! -f /etc/sudoers.d/ssclient-vpn ] && [ -d /etc/sudoers.d ]; then
        echo "%wheel ALL=(ALL) NOPASSWD: $SCRIPT_DIR/vpn-route.sh" > /etc/sudoers.d/ssclient-vpn 2>/dev/null || true
        chmod 440 /etc/sudoers.d/ssclient-vpn 2>/dev/null || true
    fi

    # 2. Detect default gateway and default interface
    DEF_GW=$(ip route show default | awk '{print $3}' | head -n1)
    DEF_DEV=$(ip route show default | awk '{print $5}' | head -n1)

    if [ -z "$DEF_GW" ] || [ -z "$DEF_DEV" ]; then
        echo "Error: Could not determine default gateway"
        exit 1
    fi

    echo "Default Gateway: $DEF_GW dev $DEF_DEV"
    echo "Shadowsocks Server: $SERVER_IP"

    # Save state for cleanup
    cat <<EOF > "$STATE_FILE"
SERVER_IP="$SERVER_IP"
DEF_GW="$DEF_GW"
DEF_DEV="$DEF_DEV"
TUN_DEV="$TUN_DEV"
EOF

    # 3. Add static route for Shadowsocks server to prevent routing loop
    ip route add "$SERVER_IP" via "$DEF_GW" dev "$DEF_DEV" 2>/dev/null || true

    # 4. Add static routes for DNS servers to ensure DNS never blocks
    ip route add "$DEF_GW" dev "$DEF_DEV" 2>/dev/null || true
    ip route add 1.1.1.1 via "$DEF_GW" dev "$DEF_DEV" 2>/dev/null || true
    ip route add 8.8.8.8 via "$DEF_GW" dev "$DEF_DEV" 2>/dev/null || true

    # 5. Clean up any previous tun dev if existing
    ip link del dev "$TUN_DEV" 2>/dev/null || true

    # 6. Create TUN device
    ip tuntap add mode tun dev "$TUN_DEV"
    ip addr add 198.18.0.1/15 dev "$TUN_DEV"
    ip link set dev "$TUN_DEV" up

    # 7. Start tun2socks
    "$TUN2SOCKS_BIN" --device "$TUN_DEV" --proxy "socks5://127.0.0.1:$SOCKS_PORT" --loglevel info > "$LOG_FILE" 2>&1 &
    TUN_PID=$!
    echo "$TUN_PID" > "$PID_FILE"

    sleep 0.4

    # 8. Route all system traffic (0.0.0.0/1 and 128.0.0.0/1) via TUN
    ip route add 0.0.0.0/1 dev "$TUN_DEV"
    ip route add 128.0.0.0/1 dev "$TUN_DEV"

    echo "VPN Mode successfully activated!"
}

stop_vpn() {
    echo "Stopping VPN Mode..."
    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
    fi

    # Remove routing rules
    ip route del 0.0.0.0/1 dev "$TUN_DEV" 2>/dev/null || true
    ip route del 128.0.0.0/1 dev "$TUN_DEV" 2>/dev/null || true
    ip route del 1.1.1.1 via "$DEF_GW" dev "$DEF_DEV" 2>/dev/null || true
    ip route del 8.8.8.8 via "$DEF_GW" dev "$DEF_DEV" 2>/dev/null || true

    if [ -n "$SERVER_IP" ] && [ -n "$DEF_GW" ] && [ -n "$DEF_DEV" ]; then
        ip route del "$SERVER_IP" via "$DEF_GW" dev "$DEF_DEV" 2>/dev/null || true
    fi

    # Kill tun2socks
    if [ -f "$PID_FILE" ]; then
        kill $(cat "$PID_FILE") 2>/dev/null || true
        rm -f "$PID_FILE"
    fi
    pkill -f "$TUN2SOCKS_BIN" 2>/dev/null || true

    # Delete TUN interface
    ip link set dev "$TUN_DEV" down 2>/dev/null || true
    ip link del dev "$TUN_DEV" 2>/dev/null || true

    rm -f "$STATE_FILE"
    echo "VPN Mode stopped."
}

case "$ACTION" in
    start)
        start_vpn
        ;;
    stop)
        stop_vpn
        ;;
    status)
        if ip link show dev "$TUN_DEV" >/dev/null 2>&1 && [ -f "$PID_FILE" ]; then
            echo "active"
        else
            echo "inactive"
        fi
        ;;
    *)
        echo "Usage: $0 {start <server_host> <socks_port>|stop|status}"
        exit 1
        ;;
esac
