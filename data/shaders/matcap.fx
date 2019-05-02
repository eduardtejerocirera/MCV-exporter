//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
#include "constants.h"

#pragma fragmentoption ARB_precision_hint_fastest

// s----------------------------------------
Texture2D    txAlbedo         : register(t0);
SamplerState samLinear        : register(s0);

//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
  float4 pos : SV_POSITION;
  float4 pos2 : POSITION;
  float3 normal   : NORMAL;
  float2 Uv : TEXCOORD0;
  float4 Color : COLOR0;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS( float4 a_pos : POSITION, float3 a_normal : NORMAL, float2 a_uv : TEXCOORD0 )
{
  VS_OUTPUT v = (VS_OUTPUT)0;
  
  float4 vertex4 = float4(a_pos.xyz, 1);
  v.pos2 = mul(vertex4, World);
  v.pos = mul(v.pos2, ViewProjection);

  v.normal = mul(a_normal, (float3x3)World);//a_normal;
  v.Color = ObjColor;

  return v;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS(VS_OUTPUT v) : SV_Target
{



  //TODO: EYE, u_tex_scale
  float u_tex_scale = 1;

  float3 N = normalize( v.normal );
  float3 E = normalize( Eye - v.pos2 );
  N = reflect(N,E);


  float3 view_N = mul(N, View);

  float2 matcap_coord = view_N.xy;//float2(view_N.x, view_N.y);
  matcap_coord.y = -matcap_coord.y;
         matcap_coord = matcap_coord * 0.48 * u_tex_scale + float2(0.5, 0.5);
  float4 matcap_color = txAlbedo.Sample(samLinear, matcap_coord);

  matcap_color = matcap_color * v.Color;
  return pow(float4( matcap_color.xyz ,1.0), 1/2.2);
  
}
