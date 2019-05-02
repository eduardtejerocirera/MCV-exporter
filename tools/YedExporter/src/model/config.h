class CConfig
{
public:
  std::string resourcesPath;
  std::string importPath;
  std::string exportPath;
  std::string importExtension;
  std::string exportExtension;

  bool processAll = false;
  std::string singleFile;

  CConfig(const std::string& filename);
  void loadOptions(int argc, char *argv[]);

  std::vector<std::string> fetchFiles() const;
  std::string getOutputFile(const std::string& inputFile) const;
};
