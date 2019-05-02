#pragma once

json loadJson(const std::string& filename);

void dbg(const char* fmt, ...);
bool fatal(const char* fmt, ...);
