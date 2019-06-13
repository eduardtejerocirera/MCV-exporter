//--------------------------------------------------------------------------------------
#include "common.fx"
#include "pbr.inc"

// --------------------------------------------------------------
// instances input data: AABB + WORLD
struct TInstance {
  float3   aabb_center;
  uint     prefab_idx;
  float3   aabb_half;
  uint     dummy2;
  float4x4 world;
};

struct TCulledInstance {
  float4x4 world;
};

struct TPrefab {
  uint id;
  uint  lod_prefab;
  float lod_threshold;
  uint num_objs;
  uint num_render_type_ids;
  uint total_num_objs;
  uint render_type_ids[6];
};

// --------------------------------------------------------------
// Holds the 6 planes to perform the culling
cbuffer TCullingPlanes : register(b11) {
  float4 planes[6];
  float3 culling_camera_pos;
  float  culling_dummy;
};

// --------------------------------------------------------------
cbuffer TCtesInstancing : register(b12) {
  uint  total_num_objs;
  uint  instance_base;
  uint2 instancing_padding;
};

// --------------------------------------------------------------
bool isVisible( TInstance instance ) {
  [unroll]
  for( int i=0; i<6; ++i ) {
    const float4 plane = planes[i];
    const float r = dot( abs( plane.xyz ), instance.aabb_half );
    const float c = dot( plane.xyz, instance.aabb_center ) + plane.w;
    if( c < -r )
      return false;
  }
  return true;
}

// --------------------------------------------------------------
[numthreads(64, 1, 1)]
void cs_cull_instances(
  uint id : SV_DispatchThreadID     // Unique id as uint
,   StructuredBuffer<TInstance>       instances        : register(t0)
,   StructuredBuffer<TPrefab>         prefabs          : register(t1)
, RWStructuredBuffer<TCulledInstance> culled_instances : register(u0)
, RWByteAddressBuffer                 draw_datas       : register(u1)
) 
{
  if( id >= total_num_objs )
    return;

  TInstance instance = instances[ id ];

  if( !isVisible( instance ) )
    return;

  TCulledInstance culled_instance;
  culled_instance.world = instance.world;

  const uint bytes_per_draw_data_id = 32;

  // Each prefab defines which draw call types must be added
  TPrefab prefab = prefabs[ instance.prefab_idx ];

  // LOD -> Change prefab type based on distance
  float  distance_to_camera = length( culling_camera_pos - instance.aabb_center );
  if( distance_to_camera < prefab.lod_threshold ) {
    if( prefab.lod_prefab < 0 )
      return;
    prefab = prefabs[prefab.lod_prefab];
  }

  for( int i=0; i<prefab.num_render_type_ids; ++i ) {
    uint render_type_id = prefab.render_type_ids[i];
    uint offset_render_type = render_type_id * bytes_per_draw_data_id;
    uint base = draw_datas.Load( offset_render_type + 20 );  // Read TDrawData[render_type_id].base

    // Atomically read+add(+1)+write. Result is recv in myIndex
    uint myIndex;
    draw_datas.InterlockedAdd( offset_render_type + 4, 1, myIndex );   // +1 to .instanceCount

    // Store the instance in the requested position
    culled_instances[ base + myIndex] = culled_instance;
  }

}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(
  in VS_INPUT input
, in uint InstanceID : SV_InstanceID
, StructuredBuffer<TCulledInstance> culled_instances : register(t0)
)
{
  TCulledInstance culled_instance = culled_instances[ instance_base + InstanceID ];
  float4x4 newWorld = culled_instance.world;
  return runObjVS( input, newWorld );
}


