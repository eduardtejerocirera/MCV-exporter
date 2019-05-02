#include "platform.h"

#define CTE_BUFFER_SLOT_CAMERAS     0
#define CTE_BUFFER_SLOT_OBJECT      1
#define CTE_BUFFER_SLOT_SHARED      2
#define CTE_BUFFER_SLOT_DEBUG_LINE  3
#define CTE_BUFFER_SLOT_SKIN_BONES  4
#define CTE_BUFFER_SLOT_LIGHT       5

// TS = TEXTURE_SLOT
#define TS_ALBEDO            0
#define TS_NORMAL            1
#define TS_METALLIC          2
#define TS_ROUGHNESS         3
#define TS_EMISSIVE          4
#define TS_AO                5

#define TS_PROJECTOR         6
#define TS_LIGHT_SHADOW_MAP  7
#define TS_ENVIRONMENT_MAP   8
#define TS_IRRADIANCE_MAP    9
#define TS_NOISE_MAP         10

#define TS_DEFERRED_ALBEDOS  11
#define TS_DEFERRED_NORMALS  12
#define TS_DEFERRED_LINEAR_DEPTH 13
#define TS_DEFERRED_ACC_LIGHTS   14


// -------------------------------------------------
// Render Outputs. Must be in sync with module_render.cpp
#define RO_COMPLETE     0
#define RO_ALBEDO       1
#define RO_NORMAL       2
#define RO_ROUGHNESS    3
#define RO_METALLIC     4
#define RO_WORLD_POS    5
#define RO_LINEAR_DEPTH 6
#define RO_AO           7

// -------------------------------------------------
#define MAX_SUPPORTED_BONES        256

#define PI 3.14159265359f

SHADER_CTE_BUFFER(TCtesCamera, CTE_BUFFER_SLOT_CAMERAS)
{
  matrix Projection;
  matrix View;
  matrix ViewProjection;
  float4 Eye;
  matrix InverseViewProjection;
  matrix CameraScreenToWorld;
  float3 CameraFront;
  float  CameraZFar;
  float3 CameraPosition;
  float  CameraZNear;
  float  CameraTanHalfFov;
  float  CameraAspectRatio;
  float2 CameraInvResolution;
};

SHADER_CTE_BUFFER(TCtesObject, CTE_BUFFER_SLOT_OBJECT)
{
  matrix World;
  float4 ObjColor;
};

SHADER_CTE_BUFFER(TCtesShared, CTE_BUFFER_SLOT_SHARED)
{
  float  GlobalWorldTime;
  int    GlobalRenderOutput;
  float  GlobalAmbientBoost;
  float  GlobalExposureAdjustment;
};

SHADER_CTE_BUFFER(TCtesDebugLine, CTE_BUFFER_SLOT_DEBUG_LINE)
{
  // The float4 for the positions is to enforce alignment
  float4 DebugSrc;
  float4 DebugDst;
  float4 DebugColor;
};

SHADER_CTE_BUFFER(TCteSkinBones, CTE_BUFFER_SLOT_SKIN_BONES)
{
  matrix Bones[MAX_SUPPORTED_BONES];
};

SHADER_CTE_BUFFER(TCtesLight, CTE_BUFFER_SLOT_LIGHT)
{
  float4 LightColor;
  float3 LightPosition;
  float  LightIntensity;
  matrix LightViewProjOffset;
  float  LightShadowStep;
  float  LightShadowInverseResolution;
  float  LightShadowStepDivResolution;
  float  LightRadius;
  float3 LightFront;      // For the sun
  float  LightDummy2;
};

