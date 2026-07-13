# Wifi.pak — credits and build notes

This pak is adapted from **josegonzalez/minui-wifi-pak** (MIT licensed) with
support added for the `trimuismart` platform (TrimUI Smart, Allwinner S3).
See LICENSE for the upstream MIT terms.

Upstream projects:
- https://github.com/josegonzalez/minui-wifi-pak   (the pak / launch.sh)
- https://github.com/josegonzalez/minui-list       (bin/trimuismart/minui-list)
- https://github.com/josegonzalez/minui-keyboard   (bin/trimuismart/minui-keyboard)
- https://github.com/josegonzalez/minui-presenter  (bin/trimuismart/minui-presenter)
- https://github.com/jqlang/jq                     (bin/arm/jq, static armhf build)

## Changes made for trimuismart

- `bin/service-on`: added a `trimuismart` branch. The RTL8723D WiFi/BT combo
  chip sits on SDIO and is powered off at boot, so bring-up drives PB2 high via
  the sunxi PIO registers (read-modify-write on 0x01C20824 / 0x01C20834) and
  then forces an SDIO rescan via /proc/driver/sunxi-mmc.1/insert before starting
  wpa_supplicant (ctrl socket at /etc/wifi/sockets) and udhcpc.
- `bin/service-off`: added `trimuismart` to the system.json wifi-flag handling.
- `launch.sh`: added `trimuismart` to allowed platforms and to write_config.
- `launch.sh`: added `kill_presenter()`. The upstream bare `killall` can race a
  just-spawned background presenter that has not exec'd yet, leaving a stale
  message overlaying the next screen. This retries until the process is gone.
- `res/settings*.json` + `launch.sh`: option strings changed from
  `true`/`false` to `On`/`Off` for readability (comparisons updated to match).

## Rebuilding the UI binaries

Inside the trimuismart toolchain container
(`docker run -it --rm -v "$PWD/workspace":/root/workspace trimuismart-toolchain /bin/bash`):

    cd /root/workspace
    git clone https://github.com/josegonzalez/minui-keyboard.git
    git clone https://github.com/josegonzalez/minui-list.git
    git clone https://github.com/josegonzalez/minui-presenter.git
    for p in minui-keyboard minui-list minui-presenter; do
        (cd "$p" && make PLATFORM=trimuismart)
    done

Each produces `<name>-trimuismart`; copy it to `bin/trimuismart/<name>`
(dropping the suffix). They build against SDL 1.2 and MinUI's own api.c, and
link only libraries already present on the device.

## Local patch to minui-presenter

The bundled `bin/trimuismart/minui-presenter` carries a local change on top of
upstream: support for explicit newlines in `--message`. Upstream splits the
message on spaces and word-wraps it, so `\n` is never a line break. The patch
splits on newlines first, word-wraps each line, and forces a row break between
them (adds a `force_break` flag to `struct Message`, switches the tokenizer to
nested `strtok_r` on "\n" then " ", and honors the flag in the packing loop).
