#!/bin/sh
# wifi_init.sh — bring up / tear down WiFi on TrimUI Smart (Allwinner S3).
# Called by PLAT_wifiEnable() in generic_wifi.c.
#
# The radio (RTL8723D on this board) sits on SDIO and is powered off at boot.
# Enabling it is a board-level sequence: drive PB2 high via the sunxi PIO
# registers, then force the SDIO host to re-scan so the chip enumerates.
# All binaries below come from the stock rootfs (already on the device).

WIFI_INTERFACE="wlan0"
SOCK_DIR="/etc/wifi/sockets"
CONF="/etc/wifi/wpa_supplicant_minui.conf"

radio_on() {
	# PB_CFG0 @ 0x01C20824: set pin-2 mux nibble [11:8] = 0x1 (OUTPUT), preserve rest
	conf=$(devmem 0x01C20824 32)
	conf=$(printf '0x%08X' "$(( conf & 0xfffff0ff | 0x00000100 ))")
	devmem 0x01C20824 32 "$conf"

	# PB_DAT @ 0x01C20834: set bit 2 = drive PB2 HIGH (chip enable), preserve rest
	data=$(devmem 0x01C20834 32)
	data=$(printf '0x%08X' "$(( data & 0xfffffffb | 0x00000004 ))")
	devmem 0x01C20834 32 "$data"

	# soft card-detect: force SDIO rescan so the now-powered chip enumerates
	if [ -e /proc/driver/sunxi-mmc.1/insert ]; then
		echo 0 > /proc/driver/sunxi-mmc.1/insert
		sleep 1
		echo 1 > /proc/driver/sunxi-mmc.1/insert
		sleep 2
	fi
	ifconfig "$WIFI_INTERFACE" up 2>/dev/null
}

start() {
	radio_on

	# our own supplicant config; ctrl_interface must match WIFI_SOCK_DIR
	# compiled into generic_wifi.c
	mkdir -p "$SOCK_DIR"
	if [ ! -f "$CONF" ]; then
		cat > "$CONF" << CONFEOF
ctrl_interface=$SOCK_DIR
update_config=1
disable_scan_offload=1
CONFEOF
	fi

	if ! pidof wpa_supplicant > /dev/null 2>&1; then
		wpa_supplicant -B -D nl80211 -i "$WIFI_INTERFACE" -c "$CONF" 2>/dev/null
		sleep 1
	fi

	# DHCP (default.script applies the lease: ip, route, resolv.conf)
	if ! pidof udhcpc > /dev/null 2>&1; then
		udhcpc -i "$WIFI_INTERFACE" -s /usr/share/udhcpc/default.script -b -q -t 5 -T 7 2>/dev/null
	fi
}

stop() {
	killall -q udhcpc 2>/dev/null
	killall -q wpa_supplicant 2>/dev/null
	ifconfig "$WIFI_INTERFACE" down 2>/dev/null
}

case "$1" in
	start|"") start ;;
	stop)     stop ;;
	*)        echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
