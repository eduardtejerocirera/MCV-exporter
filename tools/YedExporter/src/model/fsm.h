class CFSM
{
public:
  void loadXML(const std::string& filename);
  void saveJSON(const std::string& filename);

  // data model
  union vec2 {
    struct{ float x, y; };
    float value[2];
  };
  union vec3 {
    struct { float x, y, z; };
    float value[3];
  };

  struct TState
  {
    std::string id;
    vec2 pos;
    bool defaultState;
    std::string shape;
    std::string name;
    std::string params;
  };
  struct TTransition
  {
    std::string source;
    std::string target;
    std::string params;
  };
  struct TVariable
  {
    std::string name;
    std::string params;
  };

  std::vector<TState> states;
  std::vector<TTransition> transitions;
  std::vector<TVariable> variables;

  TState* getStateById(const std::string& id);
};
