CORES = fceumm gambatte gpsp pcsx_rearmed picodrive snes9x2005_plus
CORES+= mednafen_pce_fast mednafen_vb mednafen_supafaust mgba pokemini race
CORES+= fbalpha2012_neogeo fbalpha2012_cps1 fbalpha2012_cps2
# CORES+= fake-08

###############################

# optional core vars
# *_REPO=
# *_HASH=
# *_CORE=
# *_FLAGS=
# *_MAKEFILE=
# *_BUILD_PATH=

mednafen_pce_fast_REPO = https://github.com/libretro/beetle-pce-fast-libretro
mednafen_vb_REPO = https://github.com/libretro/beetle-vb-libretro

fake-08_REPO = https://github.com/jtothebell/fake-08
fake-08_CORE = fake08_libretro.so
fake-08_BUILD_PATH = fake-08/platform/libretro

fceumm_REPO = https://github.com/libretro/libretro-fceumm

gambatte_REPO = https://github.com/libretro/gambatte-libretro

mednafen_supafaust_REPO = https://github.com/libretro/supafaust

pcsx_rearmed_MAKEFILE = Makefile.libretro

picodrive_REPO = https://github.com/irixxxx/picodrive
picodrive_MAKEFILE = Makefile.libretro

pokemini_REPO = https://github.com/libretro/PokeMini
pokemini_MAKEFILE = Makefile.libretro

snes9x2005_plus_REPO = https://github.com/libretro/snes9x2005
snes9x2005_plus_FLAGS = USE_BLARGG_APU=1

###############################

fbalpha2012_neogeo_REPO = https://github.com/libretro/fbalpha2012_neogeo
fbalpha2012_cps1_REPO = https://github.com/libretro/fbalpha2012_cps1
fbalpha2012_cps1_MAKEFILE = makefile.libretro
fbalpha2012_cps2_REPO = https://github.com/libretro/fbalpha2012_cps2
fbalpha2012_cps2_MAKEFILE = makefile.libretro
fbalpha2012_neogeo_FLAGS = platform=unix CC=$(CROSS_COMPILE)gcc CXX=$(CROSS_COMPILE)g++ AR=$(CROSS_COMPILE)ar
fbalpha2012_cps1_FLAGS = platform=unix CC=$(CROSS_COMPILE)gcc CXX=$(CROSS_COMPILE)g++ AR=$(CROSS_COMPILE)ar
fbalpha2012_cps2_FLAGS = platform=unix CC=$(CROSS_COMPILE)gcc CXX=$(CROSS_COMPILE)g++ AR=$(CROSS_COMPILE)ar

include ../../all/cores/makefile
