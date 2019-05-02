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
  output.Pos.y += 0.3 * sin( GlobalWorldTime );
  output.WorldPos = output.Pos.xyz;
  output.Pos = mul(output.Pos, ViewProjection);
  output.N = mul(N, (float3x3)World);
  output.T = float4( mul(T.xyz, (float3x3)World), T.w);
  output.Uv = Uv;
  return output;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS(VS_OUTPUT input) : SV_Target
{
  float4 noise0 = txNoise.Sample(samLinear,input.Uv * 4 + 0.2 * GlobalWorldTime * float2(0,1) ) * 2 - 1.;

  // Compute coords in screen space to sample the color under me
  float3 wPos = input.WorldPos.xyz + noise0.xyz;
  float4 viewSpace = mul( float4(wPos,1.0), ViewProjection );
  float3 homoSpace = viewSpace.xyz / viewSpace.w;
  float2 uv = float2( ( homoSpace.x + 1.0 ) * 0.5, ( 1.0 - homoSpace.y ) * 0.5 );

  float shadow_factor = getShadowFactor( input.WorldPos );
  shadow_factor = 0.5 + shadow_factor * 0.5;

  float4 albedo_color = txAlbedo.Sample(samClampLinear, uv);

  int3 ss_load_coords = uint3(input.Pos.xy, 0);
  float  zlinear = txGLinearDepth.Load(ss_load_coords).x;
  float3 world_coords_under_me = getWorldCoords( ss_load_coords.xy, zlinear );
  float distance_under_water = length( input.WorldPos.xyz - world_coords_under_me);

  float amount_of_water_color = 1 - exp( -distance_under_water * 0.1 );
amount_of_water_color = 0.01;
  float4 water_color = ObjColor;
  float4 base_color = amount_of_water_color * water_color + ( 1 - amount_of_water_color) * albedo_color * ObjColor;

  float3 incident_dir = normalize(input.WorldPos - CameraPosition.xyz);
  float3 reflected_dir = normalize(reflect(incident_dir, input.N));
  float4 env_color = txEnvironmentMap.SampleLevel(samLinear, reflected_dir, 0);

  float fresnel_term = 1 - saturate( dot( input.N, -incident_dir) );
  fresnel_term = pow( fresnel_term, 5 );

  return fresnel_term * env_color + ( 1 - fresnel_term ) * base_color;
}

