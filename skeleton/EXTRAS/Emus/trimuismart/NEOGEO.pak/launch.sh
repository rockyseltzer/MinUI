#!/bin/sh

EMU_EXE=fbalpha2012_neogeo
CORES_PATH=$(dirname "$0")
###############################

EMU_TAG=$(basename "$(dirname "$0")" .pak)
ROM="$1"

mkdir -p "$BIOS_PATH/$EMU_TAG"
mkdir -p "$SAVES_PATH/$EMU_TAG"

# This core looks for neogeo.zip in the ROM's own folder, not the BIOS dir.
# Keep the BIOS in Bios/NEOGEO/ (hidden from the game list) and stage a copy
# next to the ROM only while the game runs; remove it on exit.
ROM_DIR=$(dirname "$ROM")
BIOS_SRC="$BIOS_PATH/$EMU_TAG/neogeo.zip"
BIOS_DST="$ROM_DIR/neogeo.zip"
STAGED_BIOS=0
if [ -f "$BIOS_SRC" ] && [ ! -f "$BIOS_DST" ]; then
	cp "$BIOS_SRC" "$BIOS_DST" && STAGED_BIOS=1
fi
cleanup() {
	[ "$STAGED_BIOS" = "1" ] && rm -f "$BIOS_DST"
}
trap cleanup EXIT INT TERM

HOME="$USERDATA_PATH"
cd "$HOME"

minarch.elf "$CORES_PATH/${EMU_EXE}_libretro.so" "$ROM" &> "$LOGS_PATH/$EMU_TAG.txt"
