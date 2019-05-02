//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
#include "common.fx"

//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
  float4 Pos      : SV_POSITION;
  float3 N        : NORMAL;
  float2 Uv       : TEXCOORD0;
  float3 WorldPos : TEXCOORD1;
  float4 T        : NORMAL1;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(
  float4 Pos : POSITION,
  float3 N : NORMAL,
  float2 Uv: TEXCOORD0,
  float4 T : NORMAL1
)
{
  VS_OUTPUT output = (VS_OUTPUT)0;
  output.Pos = mul(Pos, World);
  output.WorldPos = output.Pos.xyz;
  output.Pos = mul(output.Pos, ViewProjection);
  output.N = mul(N, (float3x3)World);
  output.T = float4( mul(T.xyz, (float3x3)World), T.w);
  output.Uv = Uv;
  return output;
}

VS_OUTPUT VS_noUv(
  float4 Pos : POSITION,
  float3 N : NORMAL,
  float2 Uv: TEXCOORD0
)
{
  VS_OUTPUT output = (VS_OUTPUT)0;
  output.Pos = mul(Pos, World);
  output.Uv = output.Pos.xz * -1;
  output.Pos = mul(output.Pos, ViewProjection);
  output.N = N;

  return output;
}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
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
  float3 skinN = mul(N, (float3x3)SkinMatrix);
  float3 skinT = mul(T.xyz, (float3x3)SkinMatrix);

  output.WorldPos = skinPos.xyz;
  output.Pos = mul(skinPos, ViewProjection);
  output.T = float4(skinT,T.w);
  output.N = skinN;
  output.Uv = Uv;
  return output;
}


//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS(VS_OUTPUT input) : SV_Target
{
  float4 PosLightProjection = mul(float4(input.WorldPos, 1), LightViewProjOffset);
  float3 PosLightHomoSpace = PosLightProjection.xyz / PosLightProjection.w;

  float4 N_tangent_space = txNormal.Sample(samLinear, input.Uv);  // Between 0..1
  N_tangent_space.xyz = N_tangent_space.xyz * 2 - 1.;                           // Between -1..1

  float3 T = input.T.xyz;
  float3 B = cross(T, input.N) * input.T.w;
  float3x3 TBN = float3x3(T,B,input.N);
  float3 N = mul( N_tangent_space, TBN );   // Normal from NormalMap

  float3 E = normalize( CameraPosition - input.WorldPos );
  float3 Er = reflect( -E, input.N );

  float3 L = normalize( LightPosition - input.WorldPos );
  //L = -LightFront;      // Uncomment for sun Light
  float  NdotL = saturate( dot( N, L ) );
  float  shadow_factor = min( NdotL * getShadowFactor( input.WorldPos ), 1);

  // Half vector 
  float3 H = normalize( E + L );
  float  cos_beta = saturate( dot( H, N ) );
  float  glossiness = 10;
  float  specular_factor = pow( cos_beta, glossiness );

  float4 reflected_color = txEnvironmentMap.SampleLevel(samLinear, Er, 2);
  float4 env_color = txEnvironmentMap.SampleLevel(samLinear, input.N, 2);

  //float fresnel = 1 - saturate( -dot( N, -E ) );
  //return pow( fresnel, 10 );

  float4 albedo_color = txAlbedo.Sample(samLinear, input.Uv);
  return ( specular_factor + 
           LightColor * albedo_color * 0.2 + 
           reflected_color * 0.8 
           ) * shadow_factor  + 0.2 * albedo_color;
}

