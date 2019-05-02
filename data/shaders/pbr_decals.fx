//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
#include "common.fx"

//--------------------------------------------------------------------------------------
struct V2P  // Vertex to Pixel info
{
  float4 Pos:     SV_POSITION;

  float3 decal_top_left : TEXCOORD0;
  float3 decal_axis_x : TEXCOORD1;
  float3 decal_axis_z : TEXCOORD2;

  float  opacity: TEXCOORD3;
  float2 uv:      TEXCOORD4;
  float4 color:   TEXCOORD5;
  float3 decal_axis_y : TEXCOORD6;
};

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
V2P VS(

  // From stream 0 we read the instanced mesh (the billboard)
  in float3 iPos     : POSITION           // Stream 0
, in float2 iTex0    : TEXCOORD0

  // From stream 1 we read the instance information 
, in VS_INSTANCE_WORLD instance_data      // Stream 1
, in float4 InstanceColor   : TEXCOORD6   // TimeToLife, TimeBlendingOut, ...  
)
{
  V2P output = (V2P)0;
  
  // Build a World matrix from the instance information
  float4x4 instance_world = getWorldOfInstance(instance_data);

  // Transform local vertex of the box to the world coordinates
  float4 world_pos = mul(float4(iPos,1), instance_world);
 
  // Concatenate with the instance world transform  
  // world_pos = mul(world_pos, World);

  // Transform it to camera projective space
  output.Pos = mul( world_pos, ViewProjection );

  // From the world matrix, extract the main axis x & z, and the center
  float3 center  = float3( instance_world[3][0], instance_world[3][1], instance_world[3][2] );
  float3 decal_x = float3( instance_world[0][0], instance_world[0][1], instance_world[0][2] );
  float3 decal_z = float3( instance_world[2][0], instance_world[2][1], instance_world[2][2] );
  float3 decal_y = float3( instance_world[1][0], instance_world[1][1], instance_world[1][2] );

  // Precompute in the vs the axis to compute the local coords from world coords 
  output.decal_top_left = center - decal_x * 0.5 - decal_z * 0.5;
  float decal_inv_size = 1 / ( dot( decal_x, decal_x ) );
  output.decal_axis_x = decal_x * decal_inv_size;
  output.decal_axis_z = decal_z * decal_inv_size;
  output.decal_axis_y = decal_y * decal_inv_size;

  // Blendout in the last TimeBlendingOut secs of TimeToLife
  //float TimeToLife = InstanceXtras.x;
  //float TimeBlendingOut = InstanceXtras.y;
  //output.opacity = smoothstep( 0, TimeBlendingOut, TimeToLife );
  output.opacity = 1;
  output.color = InstanceColor;

  output.uv = iTex0;

  return output;
}

//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
void PS(
  in V2P input
, out float4 o_albedo : SV_Target0
  )
{

  //o_albedo = float4(input.uv,0,1);

  // Screen coords
  float2 iPosition = input.Pos.xy;

  // As int3
  int3 ss_load_coords = uint3(iPosition, 0);

  // Recover the position of the world for that pixelx
  float  zlinear = txGLinearDepth.Load(ss_load_coords).x;
  float3 wPos = getWorldCoords(iPosition, zlinear);

  // Convert to local unit decal space
  float3 decal_top_left_to_wPos = wPos - input.decal_top_left;
  float amount_of_x = dot( decal_top_left_to_wPos, input.decal_axis_x); 
  float amount_of_z = dot( decal_top_left_to_wPos, input.decal_axis_z); 
  float amount_of_y = dot( decal_top_left_to_wPos, input.decal_axis_y); 

  //float distance_to_decal_center = length( decal_top_left_to_wPos );

  //o_albedo = float4( distance_to_decal_center,distance_to_decal_center,distance_to_decal_center,1);

  float4 decal_color = txAlbedo.Sample(samBorderColor, float2(amount_of_x,amount_of_z));
  //float4 decal_normal = txNormal.Sample(samLinear, float2(amount_of_x,amount_of_z)) * 2.0 - 1.0;
  //o_normal = decal_normal;

  //o_albedo.a *= input.opacity;
  //float4 o_albedo;

  o_albedo.xyz = input.color.xyz;
  o_albedo.a = decal_color.a;
  
  //o_normal.a = decal_color.a;
  //o_albedo.a = distance_to_decal_center;
  //o_albedo = float4( amount_of_x, amount_of_z, 0, 1 );

  // Fade out the texture as we move away from the oficial plane XZ of the decal
  float vertical_factor = 1 - abs( amount_of_y * 2 );
  o_albedo.a *= vertical_factor;

  // Change to true 'see' the boxes
  if( false ) {
    o_albedo.a += 0.3;
   
    if( (input.uv.x < 0.01 || input.uv.x > 0.99 ) || (input.uv.y < 0.01 || input.uv.y > 0.99 ) )
      o_albedo.a = 1.0;
  }

  // o_albedo = float4(1,0,0,1);
  //o_albedo = txAlbedo.Sample(samLinear, input.uv);
  //o_albedo = decal_color;

  //o_normal = float4(1,1,0,1);
  //o_self_illum = float4(1,1,0,1);
}

