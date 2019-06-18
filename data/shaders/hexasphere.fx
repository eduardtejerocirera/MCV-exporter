//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
#include "common.fx"
#include "noise.inc"

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
  float4 bgColor;
  float4 noiseColor;
  float Displacement = .2;
  float DispSpeed = 0.2;
  float NoiseSpeed;


  VS_OUTPUT output = (VS_OUTPUT)0;
  float4 noise0 = txNoise.SampleLevel(samLinear, Uv * 4 + 0.2 * GlobalWorldTime * float2(0,1), 0 ) * 2 - 1.;

  output.Pos = mul(Pos, World);
  output.N = mul(N, (float3x3)World);
  output.N = normalize(output.N);

  float _noise = snoise(float3(output.N * 0.85 + GlobalWorldTime * DispSpeed )) * .5 + .5;
  _noise = smoothstep(.45, 1.0, _noise);

  output.Pos.xyz += output.N * Displacement * _noise ;
  output.WorldPos = output.Pos.xyz;

  output.Pos = mul(output.Pos, ViewProjection);
  
  output.T = float4( mul(T.xyz, (float3x3)World), T.w);
  output.Uv = Uv;
  return output;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS(VS_OUTPUT input) : SV_Target
{
  float4 bgColor = float4(.1, 0.45, 1.0, 1);
  float4 noiseColor = float4(1.0,0,0,1);
  float  NoiseSpeed = 0.2;
  
  // Compute coords in screen space to sample the color under me
  float3 wPos = input.WorldPos.xyz;
  float4 viewSpace = mul( float4(wPos,1.0), ViewProjection );
  float3 homoSpace = viewSpace.xyz / viewSpace.w;
  float2 uv = float2( ( homoSpace.x + 1.0 ) * 0.5, ( 1.0 - homoSpace.y ) * 0.5 );

  //Get the vector pointing to camera
  float3  V = normalize(CameraPosition - input.WorldPos.xyz);
  float NdotV = max( 0.2, 1 - abs(dot( input.N, V )));
 
  float _noise = snoise(float3(input.N * 0.85 + (GlobalWorldTime - 0.1) * NoiseSpeed )) * .5 + .5;
  _noise = smoothstep(.65, 1.0, _noise);

  float4 color;
  float4 colorA = bgColor * pow(NdotV, 2) + bgColor * pow(NdotV, 4);
  float4 colorB = noiseColor * txAlbedo.Sample(samClampLinear, input.Uv) ;
          color = lerp(colorA,colorB, _noise);

  //float4 background   = txNormal.Sample(samClampLinear, uv);

  float4 background = txNormal.Sample(samClampLinear, uv);
  return color;//lerp(background, color, color.w) ;

}

