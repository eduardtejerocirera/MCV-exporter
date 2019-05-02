#include "common.fx"

struct VS_OUTPUT
{
  float4 Pos   : SV_POSITION;
  // To generate the shadows I don't need the UV's or the normal
};

// ----------------------------------------------
VS_OUTPUT VS(
  float4 iPos : POSITION
  )
{
  VS_OUTPUT output = (VS_OUTPUT)0;
  float4 world_pos = mul( iPos, World );
  output.Pos = mul(world_pos, ViewProjection );
  return output;
}

// ----------------------------------------------
VS_OUTPUT VS_instanced(
  float4 iPos : POSITION,
  VS_INSTANCE_WORLD instance_data     // Stream 1
  )
{
  VS_OUTPUT output = (VS_OUTPUT)0;
  float4x4 instanceWorld = getWorldOfInstance(instance_data);
  float4 world_pos = mul( iPos, instanceWorld );
  output.Pos = mul(world_pos, ViewProjection );
  return output;
}

// -----------------------------------------------------
VS_OUTPUT VS_skin(
  float4 iPos : POSITION,
  VS_SKINNING skinning
  )
{

  float4x4 SkinMatrix = getSkinMtx( skinning );

  VS_OUTPUT output = (VS_OUTPUT)0;

  // Skinned pos
  float4 world_pos = mul(iPos, SkinMatrix);
  output.Pos = mul(world_pos, ViewProjection );
  return output;
}
