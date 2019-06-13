#include "common.fx"

//--------------------------------------------------------------------------------------
// This shader is expected to be used only with the mesh unitQuadXY.mesh
// Where the iPos goes from 0,0..1,1
void VS(
    in float4 iPos : POSITION
  , out float4 oPos : SV_POSITION
  , out float2 oTex0 : TEXCOORD0
)
{
  // Passthrough of coords and UV's
  oPos = float4(iPos.x * 2 - 1., 1 - iPos.y * 2, 0, 1);
  oTex0 = iPos.xy;
}

//--------------------------------------------------------------------------------------
float4 PS(
    in float4 iPosition : SV_Position
  , in float2 iTex0 : TEXCOORD0
) : SV_Target
{

  float4 in_focus  = txAlbedo.Sample(samClampLinear, iTex0.xy);
  float4 out_focus  = txAlbedo1.Sample(samClampLinear, iTex0.xy);
  float  zlinear = txGLinearDepth.Load(uint3(iPosition.xy, 0)).x * CameraZFar;

  // if focus_z_center_in_focus   = 300;
  // if focus_z_margin_in_focus   =  50;
  // if focus_transition_distance = 100;

  // We want for z between 250 and 350 => all_in_focus     ++++++++++
  // We want for z between 350 and 450 => mix between in_focus and out_Focus   XXXXX
  // We want for z between 150 and 250 => mix between in_focus and out_Focus   XXXXX
  // We want for z beyond  450 or <150 => all out_Focus    ----------
  //                        300
  // ---------XXXXXXXXXX+++++F+++++XXXXXXXXXX-------------
  float distance_to_focus = abs( zlinear - focus_z_center_in_focus );
  float amount_of_out_blur = smoothstep( focus_z_margin_in_focus, focus_z_margin_in_focus + focus_transition_distance, distance_to_focus );
  amount_of_out_blur = pow( amount_of_out_blur, focus_modifier);
  
  //return amount_of_out_blur;
  return amount_of_out_blur * out_focus + ( 1. - amount_of_out_blur) * in_focus;
}
