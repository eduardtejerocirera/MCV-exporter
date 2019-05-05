//--------------------------------------------------------------------------------------
#include "common.fx"
#include "gbuffer.inc"

float3 toneMappingReinhard(float3 hdr, float k = 1.0) {
    return hdr / (hdr + k);
}

float3 gammaCorrect( float3 linear_color ) {
  return pow( abs(linear_color), 1. / 2.2 ); 
}

// -------------------------------------------------
float3 Uncharted2Tonemap(float3 x)
{
  float A = 0.15;
  float B = 0.50;
  float C = 0.10;
  float D = 0.20;
  float E = 0.02;
  float F = 0.30;
  return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float3 toneMappingUncharted2(float3 x) {
  float ExposureBias = 2.0f;
  float3 curr = Uncharted2Tonemap(ExposureBias*x);
  float W = 11.2;
  float3 whiteScale = 1.0f/Uncharted2Tonemap(W);
  float3 color = curr*whiteScale;
  return color;
}

// -------------------------------------------------
// What we actually present to the final backbuffer.
float4 PS( 
  float4 iPosition : SV_POSITION,
  float2 iUV       : TEXCOORD0
  ) : SV_Target
{

  int3 ss_load_coords = uint3(iPosition.xy, 0);

  float3 hdrColor = txAlbedo.Load(ss_load_coords).xyz;

  hdrColor *= GlobalExposureAdjustment;

  float3 tmColorReinhard = toneMappingReinhard( hdrColor );
  float3 tmColorUC2 = toneMappingUncharted2( hdrColor );
  float3 tmColor = tmColorReinhard;

  float3 gammaCorrectedColor = gammaCorrect( tmColor );

  GBuffer g;
  decodeGBuffer( iPosition.xy, g );

  if( GlobalRenderOutput == RO_COMPLETE )
    return float4( gammaCorrectedColor, 1 );

  if( GlobalRenderOutput == RO_ALBEDO )
    return txGAlbedo.Load(ss_load_coords);

  if( GlobalRenderOutput == RO_NORMAL ) {
    float3 N = txGNormal.Load(ss_load_coords).xyz;
    float3 q = float4( decodeNormal(N), 1);
    return float4( q, 1);
  }

  if( GlobalRenderOutput == RO_NORMAL_VIEW_SPACE ) {
    float3 N = txGNormal.Load(ss_load_coords).xyz;
    float3 q = float4( decodeNormal(N), 1);
    return float4( mul( q, (float3x3)View).xyz, 1);
  }
  
  if( GlobalRenderOutput == RO_ROUGHNESS ) {
    return g.roughness;
  }
  
  if( GlobalRenderOutput == RO_AO ) {
    float  ao = txAO.Load(ss_load_coords).x;
    return ao;
  }

  if( GlobalRenderOutput == RO_METALLIC ) {
    float4 albedo = txGAlbedo.Load(ss_load_coords);
    return albedo.a;
  }

  if( GlobalRenderOutput == RO_WORLD_POS ) {
    float  zlinear = txGLinearDepth.Load(ss_load_coords).x;
    float3 wPos = getWorldCoords(iPosition.xy, zlinear);
    float3 deltaWorldPos = wPos - float3( (int)wPos.x, (int)wPos.y, (int)wPos.z );
    deltaWorldPos = abs( deltaWorldPos );
    return float4( deltaWorldPos.x * deltaWorldPos.z, 0, 0, 1 );
  }
  if( GlobalRenderOutput == RO_LINEAR_DEPTH ) {
    float zLinear = txGLinearDepth.Load(ss_load_coords).x;
    return zLinear;
  }

  return float4(1,0,0,1);
}



 

