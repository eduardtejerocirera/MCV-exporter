#include "pch.h"
#include "config.h"
#include "utils/utils.h"
#include <filesystem>

namespace fs = std::experimental::filesystem;

CConfig::CConfig(const std::string& filename)
{
  const json jData = loadJson(filename);

  resourcesPath = jData.value("resourcesPath", "");
  importPath = jData.value("importPath", "");
  exportPath = jData.value("exportPath", "");
  importExtension = jData.value("importExtension", "");
  exportExtension = jData.value("exportExtension", "");
}

void CConfig::loadOptions(int argc, char *argv[])
{
  for (int i = 1; i < argc; ++i)
  {
    const std::string arg = argv[i];
    if (arg == "all")
    {
      processAll = true;
    }
    else
    {
      singleFile = arg;
    }
  }
}

std::vector<std::string> CConfig::fetchFiles() const
{
  std::vector<std::string> files;

  const std::string inputPath = resourcesPath + importPath;

  for (auto& entry : fs::directory_iterator(inputPath))
  {
    if(entry.path().extension() == importExtension)
    {
      const std::string absPath = fs::absolute(entry.path()).string();
      files.push_back(absPath);
    }
  }

  return files;
}

std::string CConfig::getOutputFile(const std::string& inputFile) const
{
  fs::path iFile(inputFile);
  std::string outputFile = resourcesPath + exportPath + iFile.stem().string() + exportExtension;
  return fs::absolute(outputFile).string();
}
