// Battery graph v2: filled area, uptime time-axis, remaining estimate
#include <stdio.h>
#include <unistd.h>
#include <msettings.h>

#include "defines.h"
#include "api.h"
#include "utils.h"

#define BATTERY_CSV USERDATA_PATH "/battery.csv"
#define MAXP 1024

static long ups[MAXP];
static int  pcts[MAXP];
static int  chgs[MAXP];


static void prune_file(int total, int base) {
    FILE* o = fopen(BATTERY_CSV ".tmp", "w");
    if (!o) return;
    int k;
    for (k = 0; k < total; k++) {
        int i = (base + k) % MAXP;
        fprintf(o, "%ld,%d,%d\n", ups[i], pcts[i], chgs[i]);
    }
    fclose(o);
    rename(BATTERY_CSV ".tmp", BATTERY_CSV);
}
int main(int argc, char* argv[]) {
    PWR_setCPUSpeed(CPU_SPEED_MENU);

    SDL_Surface* screen = GFX_init(MODE_MAIN);
    PAD_init();
    PWR_init();
    InitSettings();

    int count = 0;
    FILE* f = fopen(BATTERY_CSV, "r");
    if (f) {
        char line[64];
        long up; int pct, chg;
        while (fgets(line, sizeof(line), f)) {
            if (sscanf(line, "%ld,%d,%d", &up, &pct, &chg) == 3) {
                int i = count % MAXP;
                ups[i] = up; pcts[i] = pct; chgs[i] = chg;
                count++;
            }
        }
        fclose(f);
    }
    int total = count < MAXP ? count : MAXP;
    int base  = count <= MAXP ? 0 : (count % MAXP);
    if (count > MAXP) prune_file(total, base);

    int s = total > 0 ? total - 1 : 0;
    while (s > 0) {
        long a = ups[(base + s - 1) % MAXP];
        long b = ups[(base + s) % MAXP];
        if (a > b) break;
        s--;
    }
    int sn = total - s;

    int quit = 0, dirty = 1, show_setting = 0;

    while (!quit) {
        PAD_poll();
        if (PAD_justPressed(BTN_B)) quit = 1;
        PWR_update(&dirty, &show_setting, NULL, NULL);
        if (!dirty) { GFX_sync(); continue; }

        GFX_clear(screen);
        GFX_blitHardwareGroup(screen, show_setting);

        int  cur_pct  = sn > 0 ? pcts[(base + s + sn - 1) % MAXP] : -1;
        int  cur_chg  = sn > 0 ? chgs[(base + s + sn - 1) % MAXP] : 0;
        long now_up   = sn > 0 ? ups[(base + s + sn - 1) % MAXP] : 0;
        long first_up = sn > 0 ? ups[(base + s) % MAXP] : 0;
        long span = now_up - first_up; if (span < 1) span = 1;

        char title[48];
        if (cur_pct >= 0) snprintf(title, sizeof(title), "Battery  %d%%", cur_pct);
        else              snprintf(title, sizeof(title), "Battery");
        SDL_Surface* t = TTF_RenderUTF8_Blended(font.large, title, COLOR_WHITE);
        int ty = SCALE1(6);
        SDL_BlitSurface(t, NULL, screen, &(SDL_Rect){ SCALE1(10), ty });
        int title_h = t->h;
        SDL_FreeSurface(t);

        char rem[48];
        if (cur_pct < 0)      snprintf(rem, sizeof(rem), "Remaining: --");
        else if (cur_chg)     snprintf(rem, sizeof(rem), "Remaining: charging");
        else {
            int j = sn - 1;
            while (j > 0 && chgs[(base + s + j - 1) % MAXP] == 0) j--;
            int  run_pct = pcts[(base + s + j) % MAXP];
            long run_up  = ups[(base + s + j) % MAXP];
            int  drop = run_pct - cur_pct;
            long dt   = now_up - run_up;
            if (drop <= 0 || dt < 300) snprintf(rem, sizeof(rem), "Remaining: calculating");
            else {
                long secs = (long)((double)cur_pct * dt / drop);
                int hh = secs / 3600, mm = (secs % 3600) / 60;
                if (hh > 99) snprintf(rem, sizeof(rem), "Remaining: 99h+");
                else snprintf(rem, sizeof(rem), "Remaining: %dh %02dm", hh, mm);
            }
        }
        SDL_Surface* r = TTF_RenderUTF8_Blended(font.small, rem, COLOR_WHITE);
        int rem_h = r->h;
        SDL_BlitSurface(r, NULL, screen, &(SDL_Rect){ SCALE1(10), ty + title_h + SCALE1(2) });
        SDL_FreeSurface(r);
        SDL_Surface* cap = TTF_RenderUTF8_Blended(font.tiny, "Graph resets each session", COLOR_GRAY);
        int cap_h = cap->h;
        SDL_BlitSurface(cap, NULL, screen, &(SDL_Rect){ SCALE1(10), ty + title_h + SCALE1(2) + rem_h + SCALE1(1) });
        SDL_FreeSurface(cap);

        int ml = SCALE1(10), mr = SCALE1(28);
        int mt = ty + title_h + SCALE1(2) + rem_h + SCALE1(1) + cap_h + SCALE1(6);
        int mb = SCALE1(44);
        int px = ml, pw = screen->w - ml - mr;
        int py = mt, ph = screen->h - mt - mb;
        int baseY = py + ph;

        Uint32 c_grid = SDL_MapRGB(screen->format, 70, 70, 70);
        Uint32 c_fill = SDL_MapRGB(screen->format, 52, 168, 83);
        Uint32 c_line = SDL_MapRGB(screen->format, 130, 225, 140);
        Uint32 c_charge = SDL_MapRGB(screen->format, 190, 245, 200);

        int g;
        for (g = 0; g <= 100; g += 50) {
            int gy = baseY - (ph * g) / 100;
            SDL_FillRect(screen, &(SDL_Rect){ px, gy, pw, 1 }, c_grid);
            char pl[8]; snprintf(pl, sizeof(pl), "%d%%", g);
            SDL_Surface* pls = TTF_RenderUTF8_Blended(font.tiny, pl, COLOR_GRAY);
            SDL_BlitSurface(pls, NULL, screen, &(SDL_Rect){ px + pw + SCALE1(3), gy - pls->h / 2 });
            SDL_FreeSurface(pls);
        }

        if (sn <= 0) {
            SDL_Surface* m = TTF_RenderUTF8_Blended(font.large, "No battery data yet", COLOR_WHITE);
            SDL_BlitSurface(m, NULL, screen, &(SDL_Rect){ (screen->w - m->w) / 2, py + (ph - m->h) / 2 });
            SDL_FreeSurface(m);
        } else {
            long tickset[] = {300,600,900,1800,3600,7200,14400,21600,43200,86400};
            long tick = 86400; int ti;
            for (ti = 0; ti < 10; ti++) { if (span / tickset[ti] <= 5) { tick = tickset[ti]; break; } }
            long tk;
            for (tk = tick; tk <= span; tk += tick) {
                int gx = px + pw - (int)((double)tk * pw / span);
                SDL_FillRect(screen, &(SDL_Rect){ gx, py, 1, ph }, c_grid);
                char lab[12];
                if (tick >= 3600) snprintf(lab, sizeof(lab), "%ldh", tk / 3600);
                else              snprintf(lab, sizeof(lab), "%ldm", tk / 60);
                SDL_Surface* l = TTF_RenderUTF8_Blended(font.small, lab, COLOR_GRAY);
                SDL_BlitSurface(l, NULL, screen, &(SDL_Rect){ gx - l->w / 2, baseY + SCALE1(3) });
                SDL_FreeSurface(l);
            }

            int j2, prev_x = -1, prev_y = -1, prev_chg = 0;
            for (j2 = 0; j2 < sn; j2++) {
                long up = ups[(base + s + j2) % MAXP];
                int pct = pcts[(base + s + j2) % MAXP];
                int chg = chgs[(base + s + j2) % MAXP];
                if (pct < 0) pct = 0; if (pct > 100) pct = 100;
                int x = px + (int)((double)(up - first_up) * pw / span);
                int y = baseY - (ph * pct) / 100;
                if (prev_x >= 0) {
                    int w = x - prev_x > 0 ? x - prev_x : 1;
                    SDL_FillRect(screen, &(SDL_Rect){ prev_x, prev_y, w, baseY - prev_y }, c_fill);
                    SDL_FillRect(screen, &(SDL_Rect){ prev_x, prev_y, w, 1 }, c_line);
                    int y0 = prev_y < y ? prev_y : y;
                    int hh = (prev_y < y ? y - prev_y : prev_y - y) + 1;
                    SDL_FillRect(screen, &(SDL_Rect){ x, y0, 1, hh }, c_line);
                    if (prev_chg) SDL_FillRect(screen, &(SDL_Rect){ prev_x, baseY - SCALE1(3), w, SCALE1(3) }, c_charge);
                }
                prev_x = x; prev_y = y; prev_chg = chg;
            }
        }

        if (show_setting) GFX_blitHardwareHints(screen, show_setting);
        else GFX_blitButtonGroup((char*[]){ "B","BACK", NULL }, 0, screen, 1);

        GFX_flip(screen);
        dirty = 0;
    }

    QuitSettings();
    PWR_quit();
    GFX_quit();
    return 0;
}
