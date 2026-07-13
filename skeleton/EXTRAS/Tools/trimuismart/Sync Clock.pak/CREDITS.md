# Sync Clock.pak

One-shot NTP time sync for the TrimUI Smart.

The device has no RTC. MinUI fakes one by writing the time to
`.userdata/shared/datetime.txt` when the launcher exits and restoring it at
boot. This tool sets the system clock from an NTP server and writes that file,
so the correct time survives a power cycle.

The clock is kept in **UTC** — MinUI's boot script sets it with `date -u`, so
the device does not run on a local timezone and no offset is applied here.

Requires an existing WiFi connection (Tools > Wifi). It does not touch the
radio itself; if wlan0 has no address it says so and exits.

NTP servers are addressed by IP (162.159.200.123 Cloudflare, 216.239.35.0 /
216.239.35.4 Google) because DNS may not be configured.

## Bundled binary

`bin/trimuismart/minui-presenter` is built from
https://github.com/josegonzalez/minui-presenter (MIT) with a local patch adding
support for explicit newlines in `--message`: upstream tokenizes the message on
spaces only and word-wraps it, so a `\n` never forces a line break. The patch
splits the message on newlines first, word-wraps each line, and forces a new row
between them. See ../Wifi.pak/CREDITS.md for the build recipe.
