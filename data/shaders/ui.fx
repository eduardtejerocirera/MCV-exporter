//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
#include "common.fx"

//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
  float4 Pos : SV_POSITION;
  float2 Uv : TEXCOORD0;
  float4 Color : COLOR;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(
  float4 Pos : POSITION,
  float2 Uv: TEXCOORD0,
  float4 Color : COLOR
)
{
  VS_OUTPUT output = (VS_OUTPUT)0;
  //Pos.xyz *= sin( WorldTime );
  output.Pos = mul(Pos, World);

  output.Pos = mul(output.Pos, ViewProjection);
  output.Color = Color * ObjColor;
  output.Uv = Uv;
  return output;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS(VS_OUTPUT input) : SV_Target
{
  float2 final_uv = lerp(UIminUV, UImaxUV, input.Uv);
  float4 texture_color = txAlbedo.Sample(samLinear, final_uv.xy);
  return texture_color * input.Color * UItint;
}
