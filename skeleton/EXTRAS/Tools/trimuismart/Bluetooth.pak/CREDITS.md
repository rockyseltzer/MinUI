# Bluetooth.pak

Scan for, pair with, and connect Bluetooth devices, and optionally route all
audio over Bluetooth.

## How it works

The RTL8723D is a WiFi/BT combo chip. Its Bluetooth side is brought up by the
kernel at boot (Realtek H5 protocol on ttyS1), so `hci0` already exists — unlike
WiFi, no manual radio bring-up is needed. BlueZ (`bluetoothd`) and `bluealsa`
are both present in the stock rootfs and running.

Audio routing works by pointing ALSA's default PCM at bluealsa, which runs as
`bluealsa -p a2dp-source`. The stock `/etc/asound.conf` is preserved as
`/etc/asound.conf.stock` and restored when Bluetooth audio is turned off.

## Latency

A2DP adds roughly 200ms of latency even with a constrained buffer. This is
inherent to SBC over Bluetooth plus the receiving device's own buffering — it
is not something this pak can fix. Fine for music, menus, and slower games;
not recommended for fighting games or anything twitchy.

MinUI's boot script exports `SDL_AUDIO_ALSA_SET_BUFFER_SIZE=1`. Without it SDL
lets ALSA pick the buffer size, which over bluealsa comes out around 24000
frames — about half a second of latency. With it, latency drops to roughly the
A2DP floor.

## Known limitations

- **AirPods do not work.** They pair and report `Connected: yes` with an A2DP
  `Audio Sink` UUID, but no audio reaches them: BlueZ 5.54 cannot complete the
  A2DP stream negotiation, and restarting bluealsa reports "Couldn't get
  BlueALSA transport: No such device". This is a known AirPods/BlueZ
  incompatibility, not a fault in this pak. Ordinary SBC A2DP speakers and
  headphones (tested: JBL Clip 3) work correctly.
- Only SBC is supported (bluealsa on this device is SBC-only), so aptX Low
  Latency is not available.

## Bundled binaries

`minui-list` and `minui-presenter` are built from josegonzalez's projects (MIT):
- https://github.com/josegonzalez/minui-list
- https://github.com/josegonzalez/minui-presenter

`minui-presenter` carries a local patch adding support for explicit newlines in
`--message`. `bin/arm/jq` is a static armhf build from https://github.com/jqlang/jq.

See ../Wifi.pak/CREDITS.md for the build recipe.
