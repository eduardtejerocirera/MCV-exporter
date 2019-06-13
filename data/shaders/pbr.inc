//#include "common.fx"
//--------------------------------------------------------------------------------------
// Standard vertex for objects (without skinning)
struct VS_INPUT
{
  float4 Pos : POSITION;
  float3 N : NORMAL;
  float2 Uv: TEXCOORD0;
  float4 T : NORMAL1;
};

struct VS_INPUT_MORPH
{
  float4 Pos : POSITION0;
  float3 N   : NORMAL0;
  float2 Uv  : TEXCOORD0;

  float4 Pos1 : POSITION1;
  float3 N1   : NORMAL1;

  float4 T : NORMAL2;
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

#define MEDIUMP_FLT_MAX    65504.0
#define saturateMediump(x) min(x, MEDIUMP_FLT_MAX)

//Normal Distribution function
float D_GGX(float NoH, float a) {
    float a2 = a * a;
    float f = (NoH * a2 - NoH) * NoH + 1.0;
    return a2 / (PI * f * f);
}

float D_GGX_(float NoH, float roughness) {
    float a = NoH * roughness;
    float k = roughness / (1.0 - NoH * NoH + a * a);
    return k * k * (1.0 / PI);
}

float NDF_GGX(float a, float NdH)
{
    // Isotropic ggx.
    float a2 = a*a;
    float NdH2 = NdH * NdH;

    float denominator = NdH2 * (a2 - 1.0f) + 1.0f;
    denominator *= denominator;
    denominator *= PI;

    return a2 / denominator;
}


//Geometric SelfShadowing  term
float V_SmithGGXCorrelated(float NoV, float NoL, float a) {
    float a2 = a * a;
    float GGXL = NoV * sqrt((-NoL * a2 + NoL) * NoL + a2);
    float GGXV = NoL * sqrt((-NoV * a2 + NoV) * NoV + a2);
    return 0.5 / (GGXV + GGXL);
}

float V_SmithGGXCorrelatedFast(float NoV, float NoL, float roughness) {
    float a = roughness;
    float GGXL = NoV * (NoL * (1.0 - a) + a);
    float GGXV = NoL * (NoV * (1.0 - a) + a);
    return 0.5 / (GGXV + GGXL);
}

float Geometric_Smith_Schlick_GGX_(float a, float NdV, float NdL)
{
    // Smith schlick-GGX.
    float k = a * 0.5;
    float GV = NdV / (NdV * (1 - k) + k);
    float GL = NdL / (NdL * (1 - k) + k);
    return GV * GL;
}

//Fresnel Term
float3 F_Schlick(float VoH, float3 f0) {
    float f = pow(1.0 - VoH, 5.0);
    return f + f0 * (1.0 - f);
}

//Disney diffuse term
float F_Schlick(float VoH, float f0, float f90) {
    return f0 + (f90 - f0) * pow(1.0 - VoH, 5.0);
}

float Fd_Burley(float NoV, float NoL, float LoH, float roughness) {
    float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
    float lightScatter = F_Schlick(NoL, 1.0, f90);
    float viewScatter =  F_Schlick(NoV, 1.0, f90);
    return lightScatter * viewScatter * (1.0 / PI);
}

float Fd_Lambert() {
    return 1.0 / PI;
}

void BRDF(float3 v, float3 l, float3 n, float perceptualRoughness, float f0 )
{
   /*
    float3 h = normalize(v + l);

    float NoV = abs(dot(n, v)) + 0.00001;
    float NoL = clamp(dot(n, l), 0.0, 1.0);
    float NoH = clamp(dot(n, h), 0.0, 1.0);
    float LoH = clamp(dot(l, h), 0.0, 1.0);

    // perceptually linear roughness to roughness (see parameterization)
    float roughness = perceptualRoughness * perceptualRoughness;

    float   D = D_GGX(NoH, a);
    float3  F = F_Schlick(LoH, f0);
    float   V = V_SmithGGXCorrelated(NoV, NoL, roughness);

    // specular BRDF
    float3 Fr = (D * V) * F;

    // diffuse BRDF
    float3 Fd = diffuseColor * Fd_Lambert();







    // compute Fd and Fr from standard model

    // remapping and linearization of clear coat 
    float clearCoatFactor = 1.0;
    clearCoatRoughness = mix(0.089, 0.6, clearCoatRoughness);
    clearCoatAlpha = clearCoatRoughness * clearCoatRoughness;

    // clear coat BRDF
    float  Dc = D_GGX(clearCoatAlpha, NoH);
    float  Vc = V_Kelemen(clearCoatAlpha, LoH);
    float  Fc = F_Schlick(0.04, LoH) * clearCoat; // clear coat strength
    float Frc = (Dc * Vc) * Fc;

    // account for energy loss in the base layer
    return color * ((Fd + Fr * (1.0 - Fc)) * (1.0 - Fc) + Frc)





*/
}

//Clear constants
//https://google.github.io/filament/Filament.html#materialsystem/clearcoatmodel
float V_Kelemen(float LdH) {
    return 0.25 / (LdH * LdH);
}

float3 f0ClearCoatToSurface(const float3 f0) {
    // Approximation of iorTof0(f0ToIor(f0), 1.5)
    // This assumes that the clear coat layer has an IOR of 1.5
    return clamp(f0 * (f0 * (0.941892 - 0.263008 * f0) + 0.346479) - 0.0285998, 0.0, 1.0);
}