#!/bin/sh
# make-arcade-map.sh — generate a MinUI map.txt of friendly names for an
# arcade ROM folder, using FB Alpha's gamelist as the name source.
#
# Names only: does NOT move, copy, sort, or delete ROMs. It reads the .zip
# files already in the folder and writes <folder>/map.txt mapping each to its
# full title. First letter of each word is capitalized (existing acronyms kept).
#
# Usage: make-arcade-map.sh <roms-folder> [gamelist.txt]
#   <roms-folder>  folder containing arcade .zip files
#   [gamelist.txt] optional; auto-downloaded from FB Alpha if omitted
#
# Example: make-arcade-map.sh "/mnt/SDCARD/Roms/CPS-2 (CPS2)"

set -eu

ROM_DIR="${1:-}"
GAMELIST="${2:-}"

if [ -z "$ROM_DIR" ] || [ ! -d "$ROM_DIR" ]; then
  echo "Usage: $(basename "$0") <roms-folder> [gamelist.txt]" >&2
  echo "  Generates <roms-folder>/map.txt with friendly arcade game names." >&2
  exit 1
fi

if [ -z "$GAMELIST" ]; then
  GAMELIST="${TMPDIR:-/tmp}/fba_gamelist.txt"
  if [ ! -f "$GAMELIST" ]; then
    echo "Downloading FB Alpha gamelist..." >&2
    if ! wget -qO "$GAMELIST" \
      https://raw.githubusercontent.com/libretro/fbalpha/master/gamelist.txt; then
      echo "Error: could not download gamelist. Pass a local copy as the 2nd arg." >&2
      rm -f "$GAMELIST"; exit 1
    fi
  fi
elif [ ! -f "$GAMELIST" ]; then
  echo "Error: gamelist '$GAMELIST' not found." >&2
  exit 1
fi

if ! ls "$ROM_DIR"/*.zip >/dev/null 2>&1; then
  echo "No .zip files in '$ROM_DIR' — nothing to map." >&2
  exit 1
fi

OUT="$ROM_DIR/map.txt"

ls "$ROM_DIR" | awk -F'|' -v GL="$GAMELIST" '
  function titlecase(s,   out,i,c,cap,n){
    out=""; cap=1; n=length(s)
    for(i=1;i<=n;i++){
      c=substr(s,i,1)
      if(cap && c ~ /[a-z]/){ c=toupper(c); cap=0 }
      else if(c ~ /[A-Za-z0-9]/){ cap=0 }
      if(c==" " || c=="("){ cap=1 }
      out=out c
    }
    return out
  }
  BEGIN{
    while((getline line < GL) > 0){
      nf=split(line, F, "|")
      if(nf < 5) continue
      nm=F[2]; ttl=F[4]
      gsub(/^[ \t]+|[ \t]+$/,"",nm); gsub(/^[ \t]+|[ \t]+$/,"",ttl)
      if(nm=="" || nm=="name" || ttl=="") continue
      title[nm]=ttl
    }
  }
  {
    f=$0
    if(f !~ /\.zip$/) next
    base=f; sub(/\.zip$/,"",base)
    if(base in title){ printf "%s\t%s\n", f, titlecase(title[base]); m++ }
    else u++
  }
  END{ printf "  matched %d, unmatched %d\n", m+0, u+0 > "/dev/stderr" }
' > "$OUT"

echo "Wrote $OUT" >&2
