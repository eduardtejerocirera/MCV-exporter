//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
#include "common.fx"

//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
  float4 Pos : SV_POSITION;
  float4 Color : COLOR0;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(
  float4 Pos : POSITION,
  float4 Color : COLOR
)
{
  VS_OUTPUT output = (VS_OUTPUT)0;
  output.Pos = mul(Pos, World);
  output.Pos = mul(output.Pos, ViewProjection);
  output.Color = Color * ObjColor;
  return output;
}

// For physics, where there is no color
VS_OUTPUT VS_Pos(
  float4 Pos : POSITION
)
{
  VS_OUTPUT output = (VS_OUTPUT)0;
  output.Pos = mul(Pos, World);
  output.Pos = mul(output.Pos, ViewProjection);
  output.Color = ObjColor;
  return output;
}

// For physics, where there is no color
VS_OUTPUT VS_skin(
  float4 Pos : POSITION,
  float3 N : NORMAL,
  float2 Uv: TEXCOORD0,
  float4 T: NORMAL1,
  VS_SKINNING skinning
)
{
  VS_OUTPUT output = (VS_OUTPUT)0;

  float4x4 SkinMatrix = getSkinMtx( skinning );
  float4 skinPos = mul(Pos, SkinMatrix);

  output.Pos = mul(skinPos, ViewProjection);
  output.Color = ObjColor;
  return output;
}

// For physics, where there is no color
VS_OUTPUT VS_PosInstanced(
  float4 Pos : POSITION,
  VS_INSTANCE_WORLD instance_data
)
{
  float4x4 instanceWorld = getWorldOfInstance(instance_data);
  VS_OUTPUT output = (VS_OUTPUT)0;
  output.Pos = mul(Pos, instanceWorld);
  output.Pos = mul(output.Pos, ViewProjection);
  output.Color = ObjColor;
  return output;
}

//--------------------------------------------------------------------------------------

VS_OUTPUT VS_DebugLine(
  uint VertexID : SV_VertexID
)
{
  VS_OUTPUT output = (VS_OUTPUT)0;

  float4 Pos;
  if( VertexID == 0 ) {
    Pos = DebugSrc;
  } else {
    Pos = DebugDst;
  }
  output.Pos = mul(Pos, ViewProjection);
  output.Color = DebugColor;
  return output;
}
  
//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4x4 ptn1 = { 0, 0, 0, 0,
		  0, 0, 1, 0,
		  0, 0, 0, 0,
		  1, 0, 0, 0 };

float4x4 ptn2 = { 1, 0, 1, 0,
		  0, 0, 0, 0,
		  1, 0, 1, 0,
		  0, 0, 0, 0 };

float4x4 ptn3 = { 0, 0, 1, 0,
		  0, 1, 0, 1,
		  1, 0, 0, 0,
		  0, 1, 0, 1 };

float4x4 ptn5 = { 1, 1, 0, 1,
		  1, 0, 1, 0,
		  0, 1, 1, 1,
		  1, 0, 1, 0 };

float4x4 ptn6 = { 0, 1, 0, 1,
		  1, 1, 1, 1,
		  0, 1, 0, 1,
		  1, 1, 1, 1 };

float4x4 ptn7 = { 1, 1, 1, 1,
		  1, 1, 0, 1,
		  1, 1, 1, 1,
		  0, 1, 1, 1 };

float4 PS(VS_OUTPUT input) : SV_Target
{
  return input.Color;
}
