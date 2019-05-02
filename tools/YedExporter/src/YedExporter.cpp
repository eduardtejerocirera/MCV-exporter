// YedExporter.cpp : Este archivo contiene la función "main". La ejecución del programa comienza y termina ahí.
//

#include "pch.h"
#include <iostream>
#include "model/config.h"
#include "model/fsm.h"
#include <filesystem>

namespace fs = std::experimental::filesystem;

int main(int argc, char *argv[])
{
    // load config file
    CConfig cfg("config.json");
    cfg.loadOptions(argc, argv);

    // get files to process
    std::vector<std::string> inputFiles = cfg.fetchFiles();

    printf("Processing %d files\n", (int)inputFiles.size());

    // for each file
    for (const auto& inputFile : inputFiles)
    {
      const std::string outputFile = cfg.getOutputFile(inputFile);

      fs::path iPath(inputFile);
      fs::path oPath(outputFile);

      bool processFile = false;
      if (!cfg.singleFile.empty())
      {
        processFile = iPath.stem() == cfg.singleFile;
      }
      else
      {
        processFile = cfg.processAll || !fs::exists(oPath) || fs::last_write_time(iPath) > fs::last_write_time(oPath);
      }

      if (processFile)
      {
        printf("  %s ->%s\n", inputFile.c_str(), outputFile.c_str());

        CFSM fsm;

        // parse XML file
        fsm.loadXML(inputFile);

        // save to JSON file
        fsm.saveJSON(outputFile);
      }
    }
    printf("done\n");
}

// todo: 
// + check timestamp
// - console arguments (unique_file, new)
// - behavior tree exporter
