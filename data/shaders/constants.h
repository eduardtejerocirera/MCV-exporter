#include "platform.h"

#define CTE_BUFFER_SLOT_CAMERAS     0
#define CTE_BUFFER_SLOT_OBJECT      1
#define CTE_BUFFER_SLOT_SHARED      2
#define CTE_BUFFER_SLOT_DEBUG_LINE  3
#define CTE_BUFFER_SLOT_SKIN_BONES  4
#define CTE_BUFFER_SLOT_LIGHT       5
#define CTE_BUFFER_SLOT_BLUR        6
#define CTE_BUFFER_SLOT_FOCUS       7
#define CTE_BUFFER_SLOT_BLOOM       8
#define CTE_BUFFER_SLOT_MATERIAL    9
#define CTE_BUFFER_SLOT_UI          10
#define CTE_BUFFER_SLOT_COMP_BUFFERS 11

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

#define TS_DEFERRED_ALBEDOS  10
#define TS_DEFERRED_NORMALS  11
#define TS_DEFERRED_LINEAR_DEPTH 12
#define TS_DEFERRED_ACC_LIGHTS   13
#define TS_DEFERRED_AO           14
#define TS_DEFERRED_EMISSIVE     15

#define TS_NOISE_MAP            16


#define TS_LUT_COLOR_GRADING  17
#define TS_WHITE_NOISE        18
#define TS_PBR_DFG            19
#define TS_OLD_FRAME              20

// ---------------------------------------------
// Mixing material extra texture slots
#define TS_MIX_BLEND_WEIGHTS          21

#define TS_FIRST_SLOT_MATERIAL_0      TS_ALBEDO
#define TS_FIRST_SLOT_MATERIAL_1      TS_ALBEDO1
#define TS_FIRST_SLOT_MATERIAL_2      TS_ALBEDO2

#define TS_ALBEDO1 22
#define TS_NORMAL1 23
// #define TS_METALLIC1 24
// #define TS_ROUGHNESS1 25
#define TS_ALBEDO2 26
#define TS_NORMAL2 27
// #define TS_METALLIC2 28
// #define TS_ROUGHNESS2 29



// -------------------------------------------------
// Render Outputs. Must be in sync with module_render.cpp
#define RO_COMPLETE           0
#define RO_ALBEDO             1
#define RO_NORMAL             2
#define RO_NORMAL_VIEW_SPACE  3
#define RO_ROUGHNESS          4
#define RO_METALLIC           5
#define RO_WORLD_POS          6
#define RO_LINEAR_DEPTH       7
#define RO_AO                 8
#define RO_EMISSIVE           9

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
  matrix CameraProjWithOffset;
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
  float4 CustomValues;
};

SHADER_CTE_BUFFER(TCtesShared, CTE_BUFFER_SLOT_SHARED)
{
  float  GlobalWorldTime;
  int    GlobalRenderOutput;
  float  GlobalAmbientBoost;
  float  GlobalExposureAdjustment;

  float  GlobalFXAmount;
  float  GlobalFXVal1;
  float  GlobalFXVal2;
  float  GlobalFXVal3;

  float  GlobalLUTAmount;
	float  GlobalColorBanding;
  float  Globaldumm2;
  float  Globaldumm3;
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

SHADER_CTE_BUFFER(TCtesBlur, CTE_BUFFER_SLOT_BLUR)
{
  float4 blur_w;        // weights
  float4 blur_d;        // distances for the 1st, 2nd and 3rd tap
  float2 blur_step;     // Extra modifier
  float2 blur_center; // To keep aligned x4
};

SHADER_CTE_BUFFER(TCtesFocus, CTE_BUFFER_SLOT_FOCUS)
{
  float focus_z_center_in_focus;
  float focus_z_margin_in_focus;
  float focus_transition_distance;
  float focus_modifier;
};

SHADER_CTE_BUFFER(TCtesBloom, CTE_BUFFER_SLOT_BLOOM)
{
  float4 bloom_weights;
  float  bloom_threshold_min;
  float  bloom_threshold_max;
  float  bloom_pad1;
  float  bloom_pad2;
};

SHADER_CTE_BUFFER(TCtesMaterial, CTE_BUFFER_SLOT_MATERIAL) 
{
  // float  scalar_roughness;
  // float  scalar_metallic;
  // float  scalar_irradiance_vs_mipmaps;
  // float  material_dummy;

  float  mix_boost_r;
  float  mix_boost_g;
  float  mix_boost_b;
  float  material_dummy2;
};

SHADER_CTE_BUFFER(TCtesUI, CTE_BUFFER_SLOT_UI)
{
  float2 UIminUV;
  float2 UImaxUV;
  float4 UItint;
};
