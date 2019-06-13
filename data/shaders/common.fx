
#ifndef _COMMON_
#define _COMMON_
//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
#include "constants.h"

// ----------------------------------------
// From the object material 
Texture2D    txAlbedo         TEXTURE_SLOT(TS_ALBEDO);
Texture2D    txNormal         TEXTURE_SLOT(TS_NORMAL);
Texture2D    txMetallic       TEXTURE_SLOT(TS_METALLIC);
Texture2D    txRoughness      TEXTURE_SLOT(TS_ROUGHNESS);
Texture2D    txEmissive       TEXTURE_SLOT(TS_EMISSIVE);
Texture2D    txAOC            TEXTURE_SLOT(TS_AO);

Texture2D    txProjector      TEXTURE_SLOT(TS_PROJECTOR);
Texture2D    txLightShadowMap TEXTURE_SLOT(TS_LIGHT_SHADOW_MAP);
TextureCube  txEnvironmentMap TEXTURE_SLOT(TS_ENVIRONMENT_MAP);
TextureCube  txIrradianceMap  TEXTURE_SLOT(TS_IRRADIANCE_MAP);

Texture2D    txNoise          TEXTURE_SLOT(TS_NOISE_MAP);
Texture2D    txDFG            TEXTURE_SLOT(TS_PBR_DFG);

Texture3D    txLUT            TEXTURE_SLOT(TS_LUT_COLOR_GRADING);
Texture2D    txWhiteNoise     TEXTURE_SLOT(TS_WHITE_NOISE);

// Output from deferred
Texture2D    txGAlbedo        TEXTURE_SLOT(TS_DEFERRED_ALBEDOS);
Texture2D    txGNormal        TEXTURE_SLOT(TS_DEFERRED_NORMALS);
Texture2D    txGLinearDepth   TEXTURE_SLOT(TS_DEFERRED_LINEAR_DEPTH);
Texture2D    txAccLights      TEXTURE_SLOT(TS_DEFERRED_ACC_LIGHTS);
Texture2D    txAO             TEXTURE_SLOT(TS_DEFERRED_AO);
Texture2D    txGEmissive      TEXTURE_SLOT(TS_DEFERRED_EMISSIVE);

// Bloom
Texture2D    txBloom0         TEXTURE_SLOT(0);
Texture2D    txBloom1         TEXTURE_SLOT(1);
Texture2D    txBloom2         TEXTURE_SLOT(2);
Texture2D    txBloom3         TEXTURE_SLOT(3);

// --------------------------------------------
// Mix Material Extra Textures
// 2nd material
Texture2D    txAlbedo1         TEXTURE_SLOT( TS_ALBEDO1 );
Texture2D    txNormal1         TEXTURE_SLOT( TS_NORMAL1 );
//Texture2D    txMetallic1     TEXTURE_SLOT( TS_METALLIC1 );
//Texture2D    txRoughness1    TEXTURE_SLOT( TS_ROUGHNESS1 );
//Texture2D    txEmissive1     TEXTURE_SLOT( TS_EMISSIVE1 );
//Texture2D    txAO1           TEXTURE_SLOT( TS_AO1 );

// 3rd material
Texture2D    txAlbedo2         TEXTURE_SLOT( TS_ALBEDO2 );
Texture2D    txNormal2         TEXTURE_SLOT( TS_NORMAL2 );
//Texture2D    txMetallic2       TEXTURE_SLOT( TS_METALLIC2 );
//Texture2D    txRoughness2      TEXTURE_SLOT( TS_ROUGHNESS2 );
//Texture2D    txEmissive2     TEXTURE_SLOT( TS_EMISSIVE2 );
//Texture2D    txAO2           TEXTURE_SLOT( TS_AO2 );

Texture2D    txMixBlendWeights TEXTURE_SLOT( TS_MIX_BLEND_WEIGHTS );
// --------------------------------------------

// Samplers
SamplerState samLinear        : register(s0);
SamplerState samBorderColor   : register(s1);
SamplerComparisonState samPCF : register(s2);
SamplerState samClampLinear   : register(s3);

//--------------------------------------------------------------------------------------
// 
//--------------------------------------------------------------------------------------
// Should match the vertex_declaration.cpp @ createNew("Instance", ...
struct VS_INSTANCE_WORLD {
  float4 InstanceWorld0 : TEXCOORD2;    // Stream 1
  float4 InstanceWorld1 : TEXCOORD3;    // Stream 1
  float4 InstanceWorld2 : TEXCOORD4;    // Stream 1
  float4 InstanceWorld3 : TEXCOORD5;    // Stream 1
};

// Build a World matrix from the instance information
float4x4 getWorldOfInstance( VS_INSTANCE_WORLD d ) {
  return float4x4(d.InstanceWorld0, d.InstanceWorld1, d.InstanceWorld2, d.InstanceWorld3 );  
}

// Skinning information per vertex
struct VS_SKINNING {
  uint4  iBones   : BONES;
  float4 iWeights : WEIGHTS;
};

//--------------------------------------------------------------------------------------
// 
//--------------------------------------------------------------------------------------
float4x4 getSkinMtx( VS_SKINNING skin ) {
  // This matrix will be reused for the position, Normal, Tangent, etc
  return  Bones[skin.iBones.x] * skin.iWeights.x
        + Bones[skin.iBones.y] * skin.iWeights.y
        + Bones[skin.iBones.z] * skin.iWeights.z
        + Bones[skin.iBones.w] * skin.iWeights.w;
}

//--------------------------------------------------------------------------------------
float2 hash2(float n) { return frac(sin(float2(n, n + 1.0))*float2(43758.5453123, 22578.1459123)); }
float rand( float x ) { return frac( sin(x) * 43758.5453 ); }

float2 vogelDiskSample(int sampleIndex, int samplesCount, float phi)
{
  float GoldenAngle = 2.4f;
  
  float r = sqrt((sampleIndex + 0.5f) / (float) samplesCount);
  float theta = sampleIndex * GoldenAngle + phi;
  
  float sine = sin( theta );
  float cosine = cos( theta );
  
  return float2(r * cosine, r * sine);
}

//--------------------------------------------------------------------------------------
// 
//--------------------------------------------------------------------------------------
float shadowsTap(float2 homo_coord, float coord_z) {
  return txLightShadowMap.SampleCmp(samPCF, homo_coord, coord_z, 0).x;
}

float getShadowFactor( float3 wPos ) {

  float4 lightProjSpacePos = mul( float4(wPos,1), LightViewProjOffset );
  float3 lightHomeSpacePos = lightProjSpacePos.xyz / lightProjSpacePos.w;

  if( lightHomeSpacePos.z < 0 )
  	return 0.f;

  // Poisson distribution random points around a circle
  const float2 offsets[] = {
    float2(0,0),
    float2(-0.3700152, 0.575369),
    float2(0.5462944, 0.5835142),
    float2(-0.4171277, -0.2965972),
    float2(-0.8671125, 0.4483297),
    float2(0.183309, 0.1595028),
    float2(0.6757001, -0.4031624),
    float2(0.8230421, 0.1482845),
    float2(0.1492012, 0.9389217),
    float2(-0.2219742, -0.7762423),
    float2(-0.9708459, -0.1171268),
    float2(0.2790326, -0.8920202)
  };

  float scale_factor = LightShadowStepDivResolution;

  // # to add some kindof AO effect
  // nsamples = 24;
  // scale_factor += saturate( lightHomeSpacePos.z - 0.7 ) / 0.3 * .10;

  float angle = hash2( wPos.x + hash2( wPos.z ).x ).x;
  float cos_a = cos( angle ) * scale_factor;
  float sin_a = sin( angle ) * scale_factor;

  const int nsamples = 12;
  float shadow_factor = 0.0;
  [unroll]
  for( int i=0; i<nsamples; ++i ) {

  	float2 coord = offsets[ i ];

  	// For the AO effect
  	//float2 coord = vogelDiskSample( i, nsamples, 0 );

  	float2 rotated_coord = float2( coord.x * cos_a - coord.y * sin_a
  	                             , coord.y * cos_a + coord.x * sin_a );

  	float2 uv = lightHomeSpacePos.xy + rotated_coord; //coord * LightShadowStepDivResolution;
  	shadow_factor += shadowsTap( uv, lightHomeSpacePos.z).x;
  }

  shadow_factor /= nsamples;
  
  return shadow_factor;
}

// -----------------------------------------------------
// Converts range -1..1 to 0..1
float4 encodeNormal( float3 n, float nw ) {
   return float4(( n + 1. ) * 0.5, nw );
}

// Converts range 0..1 to -1..1
float3 decodeNormal( float3 n ) {
  return ( n.xyz * 2. - 1. );
}

float3x3 computeTBN( float3 inputN, float4 inputT ) {
  // Prepare a 3x3 matrix to convert from tangent space to world space
  float3 N = inputN; 
  float3 T = inputT.xyz;
  float3 B = cross( N, T ) * inputT.w;
  return float3x3( T, B, N );
}

//--------------------------------------------------------------------------------------
// screen_coords va entre 0..1024
//--------------------------------------------------------------------------------------
float3 getWorldCoords(float2 screen_coords, float zlinear_normalized) {

/*
  // ux = -1 .. 1
  // Si screen_coords == 0 => ux = 1
  // Si screen_coords == 512 => ux = 0
  // Si screen_coords == 1024 => ux = -1
  float ux = 1.0 - screen_coords.x * camera_inv_resolution.x * 2;
  
  // Si screen_coords =   0 => uy = 1;
  // Si screen_coords = 400 => uy = 0;
  // Si screen_coords = 800 => uy = -1;
  float uy = 1.0 - screen_coords.y * camera_inv_resolution.y * 2;
  

  float3 view_dir2 = float3( ux * camera_tan_half_fov * camera_aspect_ratio
                          , uy * camera_tan_half_fov
                          , 1.) * ( zlinear_normalized * camera_zfar );

  float3 view_dir = mul( float4( screen_coords, 1, 1 ), camera_screen_to_world ).xyz;
  
  view_dir *= ( zlinear_normalized );

  float3 wPos =
      CameraFront.xyz * view_dir.z
    + CameraLeft.xyz  * view_dir.x
    + CameraUp.xyz    * view_dir.y
    + CameraWorldPos.xyz;
  return wPos;

  // camera_screen_to_world includes all the previous operations
*/
  float3 view_dir = mul( float4( screen_coords, 1, 1 ), CameraScreenToWorld ).xyz;
  return view_dir * zlinear_normalized + CameraPosition;
}





//--------------------------------------------------------------------------------------
void computeBlendWeights( float t1_a
                        , float t2_a
                        , float t3_a
                        , out float w1
                        , out float w2 
                        , out float w3 
                        ) {
  float depth = 0.05;
  float ma = max( t1_a, max( t2_a, t3_a ) ) - depth;
  float b1 = max( t1_a - ma, 0 );
  float b2 = max( t2_a - ma, 0 );
  float b3 = max( t3_a - ma, 0 );
  float b_total = b1 + b2 + b3;
  w1 = b1 / ( b_total );
  w2 = b2 / ( b_total );
  w3 = b3 / ( b_total );
}

#endif