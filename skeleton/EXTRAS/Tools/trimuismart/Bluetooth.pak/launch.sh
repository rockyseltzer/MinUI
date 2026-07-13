#!/bin/sh
# Bluetooth.pak — scan, pair, connect, and route audio over Bluetooth.
#
# The RTL8723D combo chip's BT side is brought up by the kernel at boot (H5 on
# ttyS1), so hci0 already exists; we only manage bluetoothd/power, pairing, and
# audio routing.
#
# Audio routing works by pointing ALSA's default PCM at bluealsa, which is
# already running as `bluealsa -p a2dp-source`. The stock /etc/asound.conf is
# preserved as /etc/asound.conf.stock and restored when BT audio is disabled.
#
# NOTE: A2DP adds latency (roughly 200ms even with a constrained buffer). Fine
# for music, menus, and slower games; not recommended for twitchy action games.

set -x
PAK_DIR="$(dirname "$0")"
PAK_NAME="$(basename "$PAK_DIR")"
PAK_NAME="${PAK_NAME%.*}"

rm -f "$LOGS_PATH/$PAK_NAME.txt"
exec >>"$LOGS_PATH/$PAK_NAME.txt"
exec 2>&1

cd "$PAK_DIR" || exit 1
export PATH="$PAK_DIR/bin/arm:$PAK_DIR/bin/$PLATFORM:$PAK_DIR/bin:$PATH"

ASOUND=/etc/asound.conf
ASOUND_STOCK=/etc/asound.conf.stock
SYSTEM_JSON=/mnt/UDISK/system.json

###############################################################################
# ui helpers
###############################################################################

kill_presenter() {
    i=0
    while pgrep -f minui-presenter >/dev/null 2>&1 && [ "$i" -lt 10 ]; do
        killall minui-presenter >/dev/null 2>&1 || true
        killall -9 minui-presenter >/dev/null 2>&1 || true
        sleep 0.1
        i=$((i + 1))
    done
}

show_busy() {
    kill_presenter
    minui-presenter --message "$1" --timeout -1 &
    sleep 0.2
}

show_message() {
    kill_presenter
    minui-presenter --message "$1" --timeout "${2:-2}"
}

###############################################################################
# bluetooth state
###############################################################################

bt_enabled() {
    pidof bluetoothd >/dev/null 2>&1 || return 1
    hciconfig hci0 2>/dev/null | grep -q "UP RUNNING" || return 1
    return 0
}

bt_on() {
    hciconfig hci0 up 2>/dev/null
    if ! pidof bluetoothd >/dev/null 2>&1; then
        bluetoothd -n >/dev/null 2>&1 &
        sleep 2
    fi
    ( echo "power on"; sleep 1; echo "agent on"; sleep 1; echo "default-agent"; sleep 1; echo "quit" ) | bluetoothctl >/dev/null 2>&1
    set_system_flag 1
    bt_enabled
}

bt_off() {
    audio_bt_off
    ( echo "power off"; sleep 1; echo "quit" ) | bluetoothctl >/dev/null 2>&1
    hciconfig hci0 down 2>/dev/null
    set_system_flag 0
    return 0
}

set_system_flag() {
    [ -f "$SYSTEM_JSON" ] || return 0
    jq ".bluetooth = $1" "$SYSTEM_JSON" > /tmp/system.json.tmp 2>/dev/null && \
        mv /tmp/system.json.tmp "$SYSTEM_JSON"
    return 0
}

connected_mac() {
    bluetoothctl devices | grep '^Device ' | awk '{print $2}' | while read -r mac; do
        if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
            echo "$mac"
            return
        fi
    done
}

device_name() {
    bluetoothctl info "$1" 2>/dev/null | grep '^\s*Name:' | sed 's/.*Name: //'
}

###############################################################################
# audio routing
###############################################################################

audio_bt_enabled() {
    grep -q "type bluealsa" "$ASOUND" 2>/dev/null
}

# usage: audio_bt_on [MAC]
# With no argument, routes to whichever device is currently connected. Callers
# that have just connected a specific device should pass its MAC explicitly,
# since connected_mac() is ambiguous when more than one device is connected.
audio_bt_on() {
    mac="$1"
    [ -z "$mac" ] && mac="$(connected_mac)"
    if [ -z "$mac" ]; then
        show_message "Connect a device first" 2
        return 1
    fi

    [ -f "$ASOUND_STOCK" ] || cp "$ASOUND" "$ASOUND_STOCK"
    cp "$ASOUND_STOCK" "$ASOUND"
    cat >> "$ASOUND" << CONFEOF

# --- bluetooth audio (written by Bluetooth.pak) ---
pcm.btsink {
    type plug
    slave.pcm {
        type bluealsa
        device "$mac"
        profile "a2dp"
    }
}
pcm.!default {
    type plug
    slave.pcm "btsink"
}
CONFEOF
    sync
    return 0
}

audio_bt_off() {
    if [ -f "$ASOUND_STOCK" ]; then
        cp "$ASOUND_STOCK" "$ASOUND"
        sync
    fi
    return 0
}

###############################################################################
# screens
###############################################################################

main_screen() {
    list=/tmp/minui-list
    rm -f "$list" /tmp/minui-output

    mac="$(connected_mac)"
    if [ -n "$mac" ]; then
        cp "$PAK_DIR/res/settings.connected.json" "$list"
        name="$(device_name "$mac")"
        [ -z "$name" ] && name="$mac"
        sed -i "s/DEVICE_NAME/$name/" "$list"
    else
        cp "$PAK_DIR/res/settings.json" "$list"
    fi

    bt_enabled && sed -i "s/IS_ENABLED/1/" "$list" || sed -i "s/IS_ENABLED/0/" "$list"
    audio_bt_enabled && sed -i "s/IS_AUDIO_BT/1/" "$list" || sed -i "s/IS_AUDIO_BT/0/" "$list"

    kill_presenter
    minui-list --disable-auto-sleep --item-key settings --file "$list" \
        --format json --cancel-text "EXIT" --title "Bluetooth" \
        --write-location /tmp/minui-output --write-value state
}

scan_screen() {
    list=/tmp/minui-list
    rm -f "$list" /tmp/minui-output
    : > "$list"

    show_busy "Scanning for devices"
    ( echo "power on"; sleep 1; echo "scan on"; sleep 15; echo "scan off"; echo "quit" ) | bluetoothctl >/dev/null 2>&1
    bluetoothctl devices | grep '^Device ' | cut -d' ' -f3- | sort -u > "$list"

    if [ ! -s "$list" ]; then
        show_message "No devices found" 2
        return 1
    fi

    kill_presenter
    minui-list --disable-auto-sleep --file "$list" --format text \
        --confirm-text "CONNECT" --title "Bluetooth Devices" \
        --write-location /tmp/minui-output
}

forget_screen() {
    list=/tmp/minui-list
    rm -f "$list" /tmp/minui-output
    bluetoothctl paired-devices | grep '^Device ' | cut -d' ' -f3- | sort -u > "$list"

    if [ ! -s "$list" ]; then
        show_message "No paired devices" 2
        return 1
    fi

    kill_presenter
    minui-list --disable-auto-sleep --file "$list" --format text \
        --confirm-text "FORGET" --title "Paired Devices" \
        --write-location /tmp/minui-output
}

mac_for_name() {
    bluetoothctl devices | grep '^Device ' | while read -r _ mac name; do
        if [ "$name" = "$1" ]; then
            echo "$mac"
            return
        fi
    done
}

connect_device() {
    name="$1"
    mac="$(mac_for_name "$name")"
    if [ -z "$mac" ]; then
        show_message "Could not resolve device" 2
        return 1
    fi

    show_busy "Connecting to
$name"
    (
        echo "power on"; sleep 1
        echo "agent on"; sleep 1
        echo "default-agent"; sleep 1
        echo "pair $mac"; sleep 12
        echo "trust $mac"; sleep 2
        echo "connect $mac"; sleep 10
        echo "quit"
    ) | bluetoothctl >/dev/null 2>&1

    if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
        # if BT audio is on, repoint it at the device we just connected
        if audio_bt_enabled; then
            audio_bt_on "$mac"
        fi
        show_message "Connected to
$name" 2
        return 0
    fi

    show_message "Failed to connect to
$name" 2
    return 1
}

forget_device() {
    name="$1"
    mac="$(mac_for_name "$name")"
    [ -z "$mac" ] && return 1
    ( echo "remove $mac"; sleep 2; echo "quit" ) | bluetoothctl >/dev/null 2>&1
    show_message "Forgot
$name" 2
    return 0
}

###############################################################################

cleanup() {
    rm -f /tmp/stay_awake /tmp/minui-list /tmp/minui-output
    kill_presenter
}

main() {
    echo "1" >/tmp/stay_awake
    trap cleanup EXIT INT TERM HUP QUIT

    for b in minui-list minui-presenter jq; do
        if ! command -v "$b" >/dev/null 2>&1; then
            show_message "$b not found" 2
            return 1
        fi
    done

    while true; do
        main_screen
        [ $? -ne 0 ] && break

        out="$(cat /tmp/minui-output)"
        idx="$(echo "$out" | jq -r '.selected')"
        sel="$(echo "$out" | jq -r ".settings[$idx].name")"

        case "$sel" in
        "Enable"|"Audio to Bluetooth")
            # Enable
            o="$(echo "$out" | jq -r ".settings[0].selected")"
            v="$(echo "$out" | jq -r ".settings[0].options[$o]")"
            if [ "$v" = "On" ]; then
                if ! bt_enabled; then
                    show_busy "Enabling Bluetooth"
                    bt_on || show_message "Failed to enable Bluetooth" 2
                fi
            else
                if bt_enabled; then
                    show_busy "Disabling Bluetooth"
                    bt_off
                fi
            fi

            # Audio to Bluetooth
            o="$(echo "$out" | jq -r ".settings[1].selected")"
            v="$(echo "$out" | jq -r ".settings[1].options[$o]")"
            if [ "$v" = "On" ]; then
                audio_bt_enabled || { show_busy "Routing audio to Bluetooth"; audio_bt_on; }
            else
                audio_bt_enabled && { show_busy "Routing audio to speaker"; audio_bt_off; }
            fi
            kill_presenter
            ;;
        "Connect a device")
            if ! bt_enabled; then
                show_busy "Enabling Bluetooth"
                bt_on || { show_message "Failed to enable Bluetooth" 2; continue; }
            fi
            if scan_screen; then
                name="$(cat /tmp/minui-output)"
                [ -n "$name" ] && connect_device "$name"
            fi
            kill_presenter
            ;;
        "Forget a device")
            if forget_screen; then
                name="$(cat /tmp/minui-output)"
                [ -n "$name" ] && forget_device "$name"
            fi
            kill_presenter
            ;;
        esac
    done
}

main "$@"
