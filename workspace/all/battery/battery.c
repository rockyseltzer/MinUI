// Battery graph tool, modeled on clock.c
#include <stdio.h>
#include <unistd.h>
#include <msettings.h>

#include "defines.h"
#include "api.h"
#include "utils.h"

#define BATTERY_CSV USERDATA_PATH "/battery.csv"
#define MAXP 320

int main(int argc, char* argv[]) {
    PWR_setCPUSpeed(CPU_SPEED_MENU);

    SDL_Surface* screen = GFX_init(MODE_MAIN);
    PAD_init();
    PWR_init();
    InitSettings();

    static long ups[MAXP];
    static int  pcts[MAXP];
    int count = 0;
    FILE* f = fopen(BATTERY_CSV, "r");
    if (f) {
        char line[64];
        long up; int pct, chg;
        while (fgets(line, sizeof(line), f)) {
            if (sscanf(line, "%ld,%d,%d", &up, &pct, &chg) == 3) {
                ups[count % MAXP] = up;
                pcts[count % MAXP] = pct;
                count++;
            }
        }
        fclose(f);
    }
    int n = count < MAXP ? count : MAXP;
    int start = count <= MAXP ? 0 : (count % MAXP);

    int quit = 0;
    int dirty = 1;
    int show_setting = 0;

    while (!quit) {
        PAD_poll();
        if (PAD_justPressed(BTN_B)) quit = 1;
        PWR_update(&dirty, &show_setting, NULL, NULL);

        if (dirty) {
            GFX_clear(screen);
            GFX_blitHardwareGroup(screen, show_setting);

            int cur = n > 0 ? pcts[(start + n - 1) % MAXP] : -1;
            char title[32];
            if (cur >= 0) snprintf(title, sizeof(title), "Battery  %d%%", cur);
            else          snprintf(title, sizeof(title), "Battery");
            SDL_Surface* t = TTF_RenderUTF8_Blended(font.large, title, COLOR_WHITE);
            int title_h = t->h;
            SDL_BlitSurface(t, NULL, screen, &(SDL_Rect){ SCALE1(12), SCALE1(8) });
            SDL_FreeSurface(t);

            int ml = SCALE1(12), mr = SCALE1(12);
            int mt = SCALE1(8) + title_h + SCALE1(8);
            int mb = SCALE1(30);
            int px = ml, pw = screen->w - ml - mr;
            int py = mt, ph = screen->h - mt - mb;

            Uint32 col_grid = SDL_MapRGB(screen->format, 70, 70, 70);
            Uint32 col_line = SDL_MapRGB(screen->format, 255, 255, 255);

            int g;
            for (g = 0; g <= 100; g += 50) {
                int gy = py + ph - (ph * g) / 100;
                SDL_FillRect(screen, &(SDL_Rect){ px, gy, pw, 1 }, col_grid);
            }

            if (n <= 0) {
                SDL_Surface* m = TTF_RenderUTF8_Blended(font.large, "No battery data yet", COLOR_WHITE);
                SDL_BlitSurface(m, NULL, screen, &(SDL_Rect){ (screen->w - m->w) / 2, py + (ph - m->h) / 2 });
                SDL_FreeSurface(m);
            } else {
                int show = n < pw ? n : pw;
                int first = n - show;
                int prev_x = -1, prev_y = -1;
                long prev_up = -1;
                int k;
                for (k = 0; k < show; k++) {
                    int ri = (start + first + k) % MAXP;
                    long up = ups[ri];
                    int yp = pcts[ri]; if (yp < 0) yp = 0; if (yp > 100) yp = 100;
                    int x = px + (pw - show) + k;
                    int y = py + ph - (ph * yp) / 100;
                    int brk = (prev_up >= 0 && up < prev_up);
                    if (prev_x >= 0 && !brk) {
                        int y0 = prev_y < y ? prev_y : y;
                        int hh = (prev_y < y ? y - prev_y : prev_y - y) + 1;
                        SDL_FillRect(screen, &(SDL_Rect){ x, y0, 1, hh }, col_line);
                    }
                    SDL_FillRect(screen, &(SDL_Rect){ x, y, 1, 2 }, col_line);
                    prev_x = x; prev_y = y; prev_up = up;
                }
            }

            if (show_setting) GFX_blitHardwareHints(screen, show_setting);
            else GFX_blitButtonGroup((char*[]){ "B","BACK", NULL }, 0, screen, 1);

            GFX_flip(screen);
            dirty = 0;
        }
        else GFX_sync();
    }

    QuitSettings();
    PWR_quit();
    GFX_quit();
    return 0;
}
