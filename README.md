# MinUI — TrimUI Smart

A fork of [MinUI](https://github.com/shauninman/MinUI) focused entirely on the **TrimUI Smart** (`trimuismart`), adding arcade support, WiFi, Bluetooth audio, cheats, and clock sync.

> [!NOTE]
> This fork only targets the original TrimUI Smart (Allwinner S3, 320×240). Other
> devices are inherited from upstream and are untested here. If you have a
> different handheld, use [upstream MinUI](https://github.com/shauninman/MinUI).

## What This Fork Adds

| Feature | Summary |
| --- | --- |
| **Arcade** | Neo Geo, CPS-1 and CPS-2 via split FB Alpha cores, with automatic BIOS handling |
| **Arcade Names** | A tool that turns cryptic ROM filenames (`mslug.zip`) into real titles |
| **Battery Graph** | See what the battery actually does over time, with a runtime estimate |
| **Bluetooth** | Scan, pair, connect, and route all audio to a Bluetooth speaker |
| **Cheats** | RetroArch-format `.cht` files, toggled per code from the in-game menu |
| **Sync Clock** | The Smart has no RTC — set the clock from NTP so it survives a power cycle |
| **WiFi** | Scan, pick a network, type the password on an on-screen keyboard, auto-connect on boot |

Everything else behaves like upstream MinUI: no themes, no boxart, no settings to fiddle with.

## Supported Consoles

**Base**

- Game Boy
- Game Boy Advance
- Game Boy Color
- Nintendo Entertainment System
- PlayStation
- Sega Genesis
- Super Nintendo Entertainment System

**Extras**

- Famicom Disk System
- Neo Geo Pocket (and Color)
- Pico-8
- Pokémon mini
- Sega 32X
- Sega Game Gear
- Sega Master System
- Super Game Boy
- TurboGrafx-16 (and TurboGrafx-CD)
- Virtual Boy

**Arcade** *(added by this fork)*

| System | Folder | Core |
| --- | --- | --- |
| CPS-1 | `Roms/CPS-1 (CPS1)` | `fbalpha2012_cps1` |
| CPS-2 | `Roms/CPS-2 (CPS2)` | `fbalpha2012_cps2` |
| Neo Geo | `Roms/Neo Geo (NEOGEO)` | `fbalpha2012_neogeo` |

> [!IMPORTANT]
> These are the **split** FB Alpha cores (roughly FBA 0.2.97.29). ROMs must match
> that vintage — a modern FBNeo set will not load. A single unified "Arcade"
> folder is **not** supported; put each system's ROMs in its own folder above.

---

## Arcade Setup

### Controls

**CPS-1 / CPS-2** use all six buttons, laid out like an arcade cabinet:

|  | Light | Medium | Heavy |
| --- | --- | --- | --- |
| **Punch** | `Y` | `X` | `L` |
| **Kick** | `B` | `A` | `R` |

**Neo Geo** uses its native four buttons: `A` `B` `X` `Y`.

No configuration needed — these are the cores' defaults.

### Game Names

Arcade ROMs are named things like `mslug.zip` and `ssf2t.zip`. MinUI reads a
`map.txt` in each ROM folder to display real titles instead.

```sh
tools/make-arcade-map.sh "/path/to/Roms/CPS-2 (CPS2)"
```

Run it once per arcade folder. It reads the `.zip` files already there, looks up
their titles in FB Alpha's gamelist (downloaded automatically), and writes
`map.txt`. It **only writes names** — it never moves, renames, or deletes a ROM.

### Neo Geo BIOS

Put `neogeo.zip` in **`Bios/NEOGEO/`** and forget about it.

The core actually wants the BIOS in the ROM folder, not the BIOS folder — so the
Neo Geo pak copies it next to the game at launch and removes it on exit. That
keeps `neogeo` out of your game list, and it never touches a `neogeo.zip` you
placed in the ROM folder yourself.

---

## Cheats

Drop RetroArch-format `.cht` files in `Cheats/<SYSTEM>/`, named to match the ROM:

```
Cheats/GB/Super Example World.cht
```

In-game, open the menu and go to **Options → Cheats**. Each code is listed with
its description and toggles `OFF` / `ON`. Changes apply immediately, and your
choices are remembered per game.

> [!TIP]
> Filenames are matched flexibly — with or without the ROM extension, with or
> without region tags like `(USA)`, and honoring the display names in `map.txt`.
> Most cheat packs work as-is.

---

## Tools

### Battery Graph

**Tools → Battery**

The launcher samples the battery level in the background, and this shows it as a
graph over time — with a time axis and an estimate of how much runtime is left.
Useful for actually knowing what your battery does under load, rather than
guessing from a four-bar icon.

### Bluetooth

**Tools → Bluetooth**

Scan, pair, and connect a Bluetooth speaker or headphones, then flip **Audio to
Bluetooth** to send everything — games, menus, the lot — to it. Turn it off and
audio returns to the built-in speaker.

> [!WARNING]
> **Bluetooth audio adds roughly 200ms of latency.** That's inherent to SBC over
> A2DP plus the speaker's own buffering, not something this fork can fix. Fine
> for music, menus, and slower games; **not recommended for fighting games or
> anything twitchy.**

> [!NOTE]
> **AirPods do not work.** They pair and report as connected, but BlueZ never
> completes the audio stream negotiation and no sound reaches them — a known
> AirPods/BlueZ incompatibility. Ordinary Bluetooth speakers and headphones work
> fine.

### Sync Clock

**Tools → Sync Clock**

The TrimUI Smart has **no real-time clock** — no battery-backed RTC — so it has
no idea what time it is when you power it on. Out of the box it starts at
1 January 1970 and stays there.

This tool sets the clock from an NTP server over WiFi and saves it, so the
correct time is restored on the next boot. Sync it once and you're set; sync
again whenever it drifts.

> [!NOTE]
> The clock runs in **UTC** — MinUI sets the system clock with `date -u`, so no
> timezone offset is applied.

> [!IMPORTANT]
> Connect to WiFi first (**Tools → Wifi**). This tool doesn't turn the radio on
> for you — if there's no connection it will say so and exit.

### WiFi

**Tools → Wifi**

Scan for networks, pick one, and type the password on an on-screen keyboard.
Credentials are saved, so it reconnects on its own next time. Turn on **Start on
boot** and WiFi comes up automatically at every boot.

---

## Other Improvements

- **Japanese / CJK game names** — the UI font renders Chinese, Japanese, and
  Korean characters, so import ROMs with native-script filenames display properly
  instead of as empty boxes. A second font is bundled and can be selected in the
  config.
- **Scrolling titles** — long game names scroll (marquee-style) when highlighted,
  instead of being cut off mid-word.

---

## Installing

Same as upstream MinUI: unzip the release onto a FAT32 SD card and boot the
device. See [upstream's instructions](https://github.com/shauninman/MinUI) for
the details.

---

## Credits

Built on [**MinUI**](https://github.com/shauninman/MinUI) by Shaun Inman (GPL-3.0).

- Arcade emulation via the [**FB Alpha**](https://github.com/libretro/fbalpha) split cores.
- The CJK font and the WiFi engine (`generic_wifi.c`) are adapted from [**NextUI**](https://github.com/LoveRetro/NextUI) (GPL-3.0).
- The UI binaries (`minui-keyboard`, `minui-list`, `minui-presenter`) are josegonzalez's, cross-compiled for this platform (MIT).
- `Wifi.pak` is adapted from [**minui-wifi-pak**](https://github.com/josegonzalez/minui-wifi-pak) by josegonzalez (MIT).

Each pak's `CREDITS.md` documents its upstream sources, local patches, and how to
rebuild its binaries.
