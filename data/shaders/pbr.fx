//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
#include "common.fx"
#include "gbuffer.inc"

//--------------------------------------------------------------------------------------
// Standard vertex for objects (without skinning)
struct VS_INPUT
{
  float4 Pos : POSITION;
  float3 N : NORMAL;
  float2 Uv: TEXCOORD0;
  float4 T : NORMAL1;
};

//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
  float4 Pos      : SV_POSITION;
  float3 N        : NORMAL;
  float2 Uv       : TEXCOORD0;
  float3 WorldPos : TEXCOORD1;
  float4 T        : NORMAL1;
  float4 Color    : COLOR0;
};

//--------------------------------------------------------------------------------------
// This is used by normal rendering, skin rendering and instancing rendering
VS_OUTPUT runObjVS(VS_INPUT input, float4x4 world ) {
  VS_OUTPUT output = (VS_OUTPUT)0;
  output.Pos = mul(input.Pos, world);
  output.WorldPos = output.Pos.xyz;
  output.Pos = mul(output.Pos, ViewProjection);
  output.N = mul(input.N, (float3x3)world);
  output.T = float4( mul(input.T.xyz, (float3x3)world), input.T.w);
  output.Uv = input.Uv;
  output.Color = ObjColor; //Tint Color from constants.h
  return output;
}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(
  VS_INPUT input
)
{
  // Use world from the constants uniform
  return runObjVS( input, World );
}

//--------------------------------------------------------------------------------------
// Vertex Shader for Skin, using standard vertex + skin info
//--------------------------------------------------------------------------------------
VS_OUTPUT VS_skin(
  VS_INPUT input,
  VS_SKINNING skinning
)
{
  float4x4 SkinMatrix = getSkinMtx( skinning );
  return runObjVS( input, SkinMatrix );
}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS_instanced (
  VS_INPUT input,
  VS_INSTANCE_WORLD instance_data     // Stream 1
)
{
  // Use world from the instance
  float4x4 instanceWorld = getWorldOfInstance(instance_data);
  return runObjVS( input, instanceWorld );
}

//--------------------------------------------------------------------------------------
// Pixel Shader to fill the gBuffer
//--------------------------------------------------------------------------------------
void PS(
      VS_OUTPUT input
, out float4 o_albedo : SV_Target0
, out float4 o_normal : SV_Target1
, out float1 o_depth  : SV_Target2
)
{

  float4 albedo_color = txAlbedo.Sample(samLinear, input.Uv);
  o_albedo.xyz = albedo_color.xyz * input.Color;
  o_albedo.a = txMetallic.Sample(samLinear, input.Uv).r;

  // Normal mapping
  float4 N_tangent_space = txNormal.Sample(samLinear, input.Uv);  // Between 0..1
  N_tangent_space.xyz = N_tangent_space.xyz * 2 - 1.;                           // Between -1..1

  float3 T = input.T.xyz;
  float3 B = cross(T, input.N) * input.T.w;
  float3x3 TBN = float3x3(T,B,input.N);
  float3 N = mul( N_tangent_space.xyz, TBN );   // Normal from NormalMap

  // Save roughness in the alpha coord of the N render target
  float roughness = txRoughness.Sample(samLinear, input.Uv).r;
  o_normal = encodeNormal(N, roughness);

  float3 cam2obj = input.WorldPos.xyz - CameraPosition.xyz;
  float  linear_depth = dot( cam2obj, CameraFront ) / CameraZFar;

  o_depth = linear_depth;
}

// -------------------------------------------------
// The output of the deferred before the postFX
float4 PS_GBuffer_Resolve( 
  float4 iPosition   : SV_POSITION,
  float2 iUV         : TEXCOORD0
  ) : SV_Target
{
  int3 ss_load_coords = uint3(iPosition.xy, 0);

  float4 acc_light = txAccLights.Load(ss_load_coords);
  float4 albedo_color = txGAlbedo.Load(ss_load_coords);
  float  linear_depth = txGLinearDepth.Sample(samLinear, iUV).x;
  //return float4( 0.5, 1, 0, 1);
  return acc_light;
}

// -------------------------------------------------
// Gloss = 1 - rough*rough
float3 Specular_F_Roughness(float3 specularColor, float gloss, float3 h, float3 v) {
  // Sclick using roughness to attenuate fresnel.
  return (specularColor + (max(gloss, specularColor) - specularColor) * pow((1 - saturate(dot(v, h))), 5));
}

float NormalDistribution_GGX(float a, float NdH)
{
    // Isotropic ggx.
    float a2 = a*a;
    float NdH2 = NdH * NdH;

    float denominator = NdH2 * (a2 - 1.0f) + 1.0f;
    denominator *= denominator;
    denominator *= PI;

    return a2 / denominator;
}

float Geometric_Smith_Schlick_GGX(float a, float NdV, float NdL)
{
        // Smith schlick-GGX.
    float k = a * 0.5f;
    float GV = NdV / (NdV * (1 - k) + k);
    float GL = NdL / (NdL * (1 - k) + k);
    return GV * GL;
}

float Specular_D(float a, float NdH)
{
    return NormalDistribution_GGX(a, NdH);
}

float Specular_G(float a, float NdV, float NdL, float NdH, float VdH, float LdV) 
{
    return Geometric_Smith_Schlick_GGX( a, NdV, NdL );
}

float3 Fresnel_Schlick(float3 specularColor, float3 h, float3 v)
{
    return (specularColor + (1.0f - specularColor) * pow((1.0f - saturate(dot(v, h))), 5));
}

float3 Specular_F(float3 specularColor, float3 h, float3 v)
{
    return Fresnel_Schlick(specularColor, h, v);
}

float3 Specular(float3 specularColor, float3 h, float3 v, float3 l, float a, float NdL, float NdV, float NdH, float VdH, float LdV)
{
    return ((Specular_D(a, NdH) * Specular_G(a, NdV, NdL, NdH, VdH, LdV)) * Specular_F(specularColor, v, h) ) / (4.0f * NdL * NdV + 0.0001f);
}

// -------------------------------------------------
float4 PS_Ambient(
  in float4 iPosition : SV_Position
, in float2 iUV : TEXCOORD0
) : SV_Target
{

  // Declare some float3 to store the values from the GBuffer
  GBuffer g;
  decodeGBuffer( iPosition.xy, g );

  // if roughness = 0 -> I want to use the miplevel 0, the all-detailed image
  // if roughness = 1 -> I will use the most blurred image, the 8-th mipmap, If image was 256x256 => 1x1
  float mipIndex = g.roughness * g.roughness * 8.0f;
  float3 env = txEnvironmentMap.SampleLevel(samLinear, g.reflected_dir, mipIndex).xyz;
  // Convert the color to linear also.
  env = pow(abs(env), 2.2f);
  //return float4( env, 1 );

  // The irrandiance, is read using the N direction.
  // Here we are sampling using the cubemap-miplevel 4, and the already blurred txIrradiance texture
  // and mixing it in base to the scalar_irradiance_vs_mipmaps which comes from the ImGui.
  // Remove the interpolation in the final version!!!
  float3 irradiance_mipmaps = txEnvironmentMap.SampleLevel(samLinear, g.N, 4).xyz;
  float3 irradiance = irradiance_mipmaps;
  float3 irradiance_texture = txIrradianceMap.Sample(samLinear, g.N).xyz;
  irradiance = irradiance_texture;
  //return float4( irradiance_texture, 1 );
  //float3 irradiance = irradiance_texture * scalar_irradiance_vs_mipmaps + irradiance_mipmaps * ( 1. - scalar_irradiance_vs_mipmaps );
  //return float4( irradiance, 1 );

  // How much the environment we see
  float3 env_fresnel = Specular_F_Roughness(g.specular_color, 1. - g.roughness * g.roughness, g.N, g.view_dir);
  //return float4(env_fresnel, 1 );

  float g_ReflectionIntensity = 1.0;
  float g_AmbientLightIntensity = 1.0;

  float4 self_illum = float4(0,0,0,0); //txGSelfIllum.Load(uint3(iPosition.xy,0));

  float4 final_color = float4(env_fresnel * env * g_ReflectionIntensity + 
                              g.albedo.xyz * irradiance * g_AmbientLightIntensity
                              , 1.0f) + self_illum;

  return final_color * GlobalAmbientBoost;
}

// ----------------------------------------
// Passthrough for the lights geometry
void VS_pass(
  in float4 iPos : POSITION
, out float4 oPos : SV_POSITION
) {
  float4 world_pos = mul(iPos, World);
  oPos = mul(world_pos, ViewProjection);
}

// ----------------------------------------
void VS_skybox( 
  in float4 iPosition  : POSITION 
, in float4 iColor     : COLOR0 
, out float4 oPosition : SV_Position 
) {
  // Convert the range 0..1 from iPosition to -1..1 to match the homo space
  oPosition = float4(iPosition.x * 2 - 1., 1 - iPosition.y * 2, 1, 1);
}

// --------------------------------------------------------
float4 PS_skybox( in float4 iPosition : SV_Position ) : SV_Target
{
  float3 view_dir = mul( float4( iPosition.xy, 1, 1 ), CameraScreenToWorld ).xyz;
  float4 skybox_color = txEnvironmentMap.Sample(samLinear, view_dir);
  return float4(skybox_color.xyz,1) * GlobalAmbientBoost;
}

// --------------------------------------------------------
float3 Diffuse(float3 pAlbedo) {
    return pAlbedo/PI;
}

// --------------------------------------------------------
float4 shade( float4 iPosition, bool use_shadows ) {

  // Declare some float3 to store the values from the GBuffer
  GBuffer g;
  decodeGBuffer( iPosition.xy, g );

  // Shadow factor entre 0 (totalmente en sombra) y 1 (no ocluido)
  float shadow_factor = use_shadows ? getShadowFactor( g.wPos ) : 1.; 

  // From wPos to Light
  float3 light_dir_full = LightPosition.xyz - g.wPos;
  float  distance_to_light = length( light_dir_full );
  float3 light_dir = light_dir_full / distance_to_light;

  float  NdL = saturate(dot(g.N, light_dir));
  float  NdV = saturate(dot(g.N, g.view_dir));
  float3 h   = normalize(light_dir + g.view_dir); // half vector
  
  float  NdH = saturate(dot(g.N, h));
  float  VdH = saturate(dot(g.view_dir, h));
  float  LdV = saturate(dot(light_dir, g.view_dir));
  float  a   = max(0.001f, g.roughness * g.roughness);
  float3 cDiff = Diffuse(g.albedo);
  float3 cSpec = Specular(g.specular_color, h, g.view_dir, light_dir, a, NdL, NdV, NdH, VdH, LdV);

  float att = saturate( distance_to_light / LightRadius );
  att = 1. - att;
  float3 final_color = LightColor.xyz * NdL * (cDiff * (1.0f - cSpec) + cSpec) * att * LightIntensity * shadow_factor;
  return float4( final_color, 1 );
}

// -------------------------------------------------
float4 PS_point_lights(
  in float4 iPosition : SV_Position
) : SV_Target
{
  return shade( iPosition, false );
}

float4 PS_dir_lights(
  in float4 iPosition : SV_Position
) : SV_Target
{
  return shade( iPosition, true );
}



