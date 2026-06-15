#ifndef UTILS_H
#define UTILS_H

#include <stdint.h>

int prefixMatch(char* pre, char* str);
int suffixMatch(char* suf, char* str);
int exactMatch(char* str1, char* str2);
int containsString(char* haystack, char* needle);
int hide(char* file_name);

void getDisplayName(const char* in_name, char* out_name);
void getEmuName(const char* in_name, char* out_name);
void getEmuPath(char* emu_name, char* pak_path);

void normalizeNewline(char* line);
void trimTrailingNewlines(char* line);
void trimSortingMeta(char** str);

int exists(char* path);
void touch(char* path);
void putFile(char* path, char* contents);
char* allocFile(char* path); // caller must free
void getFile(char* path, char* buffer, size_t buffer_size);
void putInt(char* path, int value);
int getInt(char* path);

uint64_t getMicroseconds(void);

static inline int clamp(int x, int lower, int upper) { return x < lower ? lower : (x > upper ? upper : x); }
static inline double clampd(double x, double lower, double upper) { return x < lower ? lower : (x > upper ? upper : x); }
#endif
