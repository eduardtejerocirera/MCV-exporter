#include "pch.h"
#include "fsm.h"
#include "utils/utils.h"
#include <fstream>
#include <iomanip>

using namespace tinyxml2;

namespace
{
  bool isGroupElement(XMLElement* elem)
  {
    const char* attrValue = elem->Attribute("yfiles.foldertype");
    return attrValue && strcmp(attrValue, "group") == 0;
  }

  XMLElement* getXMLElementByAttribute(XMLElement* root, const char* elemName, const char* attrName, const char* attrValue)
  {
    XMLElement* elem = root->FirstChildElement(elemName);
    while (elem)
    {
      const char* elemAttrValue = elem->Attribute(attrName);
      if (elemAttrValue && strcmp(elemAttrValue, attrValue) == 0)
      {
        return elem;
      }

      elem = elem->NextSiblingElement(elemName);
    }

    return nullptr;
  }

  XMLElement* getGroup(XMLElement* root, const char* groupName)
  {
    XMLElement* elem = root->FirstChildElement("node");
    while (elem)
    {
      if (isGroupElement(elem))
      {
        XMLElement* XMLdata = getXMLElementByAttribute(elem, "data", "key", "d6");
        if (XMLdata)
        {
          
          XMLElement* label = XMLdata->FirstChildElement("y:ProxyAutoBoundsNode");
          label = label->FirstChildElement("y:Realizers");
          label = label->FirstChildElement("y:GroupNode");
          label = label->FirstChildElement("y:NodeLabel");
          const char* groupLabel = label->FirstChild()->Value();
          if (strcmp(groupLabel, groupName) == 0)
          {
            return elem->FirstChildElement("graph");
          }
        }
      }

      elem = elem->NextSiblingElement("node");
    }

    return nullptr;
  }
}

void CFSM::loadXML(const std::string& filename)
{
  XMLDocument doc;
  XMLError result = doc.LoadFile(filename.c_str());
  if (result != XML_SUCCESS)
  {
    return;
  }

  XMLElement* XMLgraph = doc.FirstChildElement("graphml")->FirstChildElement("graph");

  // STATES
  XMLElement* XMLstate = XMLgraph->FirstChildElement("node");
  while (XMLstate)
  {
    const bool isGroup = isGroupElement(XMLstate);

    if (!isGroup)
    {
      XMLElement* XMLdata = getXMLElementByAttribute(XMLstate, "data", "key", "d5");
      XMLElement* XMLlabel = getXMLElementByAttribute(XMLstate, "data", "key", "d6");

      if (XMLdata && XMLlabel)
      {
        auto bla = XMLlabel->FirstChildElement("y:ShapeNode")->FirstChildElement("y:Fill")->Attribute("color");
        TState state;
        state.id = XMLstate->Attribute("id");
        state.pos.x = std::stof(XMLlabel->FirstChildElement("y:ShapeNode")->FirstChildElement("y:Geometry")->Attribute("x"));
        state.pos.y = std::stof(XMLlabel->FirstChildElement("y:ShapeNode")->FirstChildElement("y:Geometry")->Attribute("y"));
        state.shape = XMLlabel->FirstChildElement("y:ShapeNode")->FirstChildElement("y:Shape")->Attribute("type");
        state.defaultState = !std::strcmp(XMLlabel->FirstChildElement("y:ShapeNode")->FirstChildElement("y:Fill")->Attribute("color"), "#FF0000");
        state.name = XMLlabel->FirstChildElement("y:ShapeNode")->FirstChildElement("y:NodeLabel")->FirstChild()->Value();
        state.params = XMLdata->FirstChild()->Value();

        states.push_back(std::move(state));
      }
    }

    XMLstate = XMLstate->NextSiblingElement("node");
  }

  // TRANSITIONS
  XMLElement* XMLedge = XMLgraph->FirstChildElement("edge");
  while (XMLedge)
  {
    XMLElement* XMLdata = getXMLElementByAttribute(XMLedge, "data", "key", "d9");

    if (XMLdata)
    {
      TState* source = getStateById(XMLedge->Attribute("source"));
      TState* target = getStateById(XMLedge->Attribute("target"));

      if (source && target)
      {
        TTransition tr;
        tr.source = source->name;
        tr.target = target->name;
        tr.params = XMLdata->FirstChild()->Value();

        transitions.push_back(std::move(tr));
      }
    }

    XMLedge = XMLedge->NextSiblingElement("edge");
  }

  // VARIABLES
  XMLElement* XMLvariables = getGroup(XMLgraph, "variables");
  XMLElement* XMLvar = XMLvariables->FirstChildElement("node");
  while (XMLvar)
  {
    XMLElement* XMLdata = getXMLElementByAttribute(XMLvar, "data", "key", "d5");
    XMLElement* XMLlabel = getXMLElementByAttribute(XMLvar, "data", "key", "d6");

    if (XMLdata && XMLlabel)
    {
      TVariable var;
      var.name = XMLlabel->FirstChildElement("y:ShapeNode")->FirstChildElement("y:NodeLabel")->FirstChild()->Value();
      var.params = XMLdata->FirstChild()->Value();

      variables.push_back(std::move(var));
    }

    XMLvar = XMLvar->NextSiblingElement("node");
  }
}

void CFSM::saveJSON(const std::string& filename)
{
  json jData;

  // STATES
  json jStates = json::array();
  for (const auto& st : states)
  {
    json jState = json::parse(st.params);
    jState["id"] = st.id;
    jState["name"] = st.name;

    if(st.defaultState)
      jState["default"] = st.defaultState;

    jState["pos"] = st.pos.value;

    if(!st.shape.empty())
      jState["shape"] = st.shape;

    jStates.push_back(jState);
  }
  jData["states"] = jStates;

  // TRANSITIONS
  json jTransitions = json::array();
  for (const auto& tr : transitions)
  {
    json jTransition = json::parse(tr.params);
    jTransition["source"] = tr.source;
    jTransition["target"] = tr.target;

    jTransitions.push_back(jTransition);
  }
  jData["transitions"] = jTransitions;

  // VARIABLES
  json jVariables = json::array();
  for (const auto& var : variables)
  {
    json jVar = json::parse(var.params);
    jVar["name"] = var.name;

    jVariables.push_back(jVar);
  }
  jData["variables"] = jVariables;

  std::ofstream o(filename);
  o << std::setw(4) << jData << std::endl;
}

CFSM::TState* CFSM::getStateById(const std::string& id)
{
  auto it = std::find_if(states.begin(), states.end(), [&id](const TState& st) {
    return st.id == id;
  });
  return it != states.end() ? &(*it) : nullptr;
}
