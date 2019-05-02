#include "pch.h"
#include "utils.h"
#include <fstream>
#include <windows.h>

void dbg(const char* format, ...) {
  va_list argptr;
  va_start(argptr, format);
  char dest[1024 * 16];
  _vsnprintf(dest, sizeof(dest), format, argptr);
  va_end(argptr);
  ::OutputDebugString(dest);
}

bool fatal(const char* format, ...) {
  va_list argptr;
  va_start(argptr, format);
  char dest[1024 * 16];
  _vsnprintf(dest, sizeof(dest), format, argptr);
  va_end(argptr);
  ::OutputDebugString(dest);

  if (MessageBox(nullptr, dest, "Error!", MB_RETRYCANCEL) == IDCANCEL)
    exit(-1);
  return false;
}

// --------------------------------------------------------
json loadJson(const std::string& filename) {

  json j;

  while (true) {

    std::ifstream ifs(filename.c_str());
    if (!ifs.is_open()) {
      fatal("Failed to open json file %s\n", filename.c_str());
      continue;
    }

#ifdef NDEBUG

    j = json::parse(ifs, nullptr, false);
    if (j.is_discarded()) {
      ifs.close();
      fatal("Failed to parse json file %s\n", filename.c_str());
      continue;
    }

#else

    try
    {
      // parsing input with a syntax error
      j = json::parse(ifs);
    }
    catch (json::parse_error& e)
    {
      ifs.close();
      // output exception information
      fatal("Failed to parse json file %s\n%s\nAt offset: %d"
        , filename.c_str(), e.what(), e.byte);
      continue;
    }

#endif

    // The json is correct, we can leave the while loop
    break;
  }

  return j;
}
