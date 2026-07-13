#!/bin/sh
# Sync Clock.pak — one-shot NTP time sync.
#
# The TrimUI Smart has no RTC; MinUI fakes one by saving the time to
# $DATETIME_PATH on exit and restoring it at boot. This tool sets the system
# clock from an NTP server and writes $DATETIME_PATH so the correct time
# survives a power cycle.
#
# Requires an existing WiFi connection (use Tools > Wifi to connect).
#
# NOTE: the clock is kept in UTC. MinUI's boot script sets the system clock with
# `date -u`, so the device runs on UTC rather than a local timezone; NTP syncs
# UTC and this tool does not apply any timezone offset. Times shown by the
# device (and by this tool) are therefore UTC, not local time.

set -x
PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"

rm -f "$LOGS_PATH/$PAK_NAME.txt"
exec >>"$LOGS_PATH/$PAK_NAME.txt"
exec 2>&1

cd "$PAK_DIR" || exit 1
export PATH="$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin:$PATH"

# NTP servers by IP — DNS may not be available.
NTP_SERVERS="162.159.200.123 216.239.35.0 216.239.35.4"
DATETIME_PATH="${DATETIME_PATH:-$SDCARD_PATH/.userdata/shared/datetime.txt}"

kill_presenter() {
    i=0
    while pgrep -f minui-presenter >/dev/null 2>&1 && [ "$i" -lt 10 ]; do
        killall minui-presenter >/dev/null 2>&1 || true
        killall -9 minui-presenter >/dev/null 2>&1 || true
        sleep 0.1
        i=$((i + 1))
    done
}

# transient message (dismissed by us)
show_busy() {
    kill_presenter
    minui-presenter --message "$1" --timeout -1 &
    sleep 0.2
}

# final message — waits for a button press.
# NOTE: timeout must be 0 here, not -1. Per minui-presenter's docs, a negative
# timeout explicitly ignores all button input (it is meant for background
# messages killed externally); 0 means "run until a configured button is
# pressed", which is what a dismissable confirmation screen needs.
show_result() {
    kill_presenter
    minui-presenter --message "$1" --timeout 0 \
        --confirm-button A --confirm-text "OK" --confirm-show
}

cleanup() {
    rm -f /tmp/stay_awake
    kill_presenter
}

main() {
    echo "1" >/tmp/stay_awake
    trap cleanup EXIT INT TERM HUP QUIT

    if ! command -v minui-presenter >/dev/null 2>&1; then
        echo "minui-presenter not found"
        return 1
    fi

    # Option A: require an existing connection; don't touch the radio.
    ip_address="$(ip -4 addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"
    if [ -z "$ip_address" ]; then
        show_result "Not connected.
Connect via Tools > Wifi first."
        return 1
    fi
    echo "wlan0 ip: $ip_address"

    show_busy "Syncing..."

    synced=false
    for server in $NTP_SERVERS; do
        echo "trying ntp server $server"
        if ntpd -q -n -p "$server"; then
            synced=true
            break
        fi
    done

    if [ "$synced" != true ]; then
        show_result "Sync failed.
Check your connection."
        return 1
    fi

    # Persist for the fake RTC: MinUI restores this at boot (format: %F %T)
    mkdir -p "$(dirname "$DATETIME_PATH")"
    date +'%F %T' >"$DATETIME_PATH"
    sync
    echo "wrote $DATETIME_PATH: $(cat "$DATETIME_PATH")"

    show_result "Clock set (UTC)
$(date +'%Y-%m-%d %H:%M')"
    return 0
}

main "$@"
