//--------------------------------------------------------------------------------------
#include "common.fx"
#include "pbr.inc"

// --------------------------------------------------------------
struct TInstance {
  float3 pos;
  float  scale;
};

// --------------------------------------------------------------
[numthreads(64, 1, 1)]
void cs_particles_orbit( 
  uint thread_id : SV_DispatchThreadID,
  uint group_id  : SV_GroupID,
  uint group_idx : SV_GroupIndex,
  RWStructuredBuffer<TInstance> instances : register(u0)
) {
  uint id = thread_id;

  float2 rand_vals = hash2( id );

  float angle = 2 * PI * rand( rand_vals.x );
  angle += GlobalWorldTime * ( 1 + 0.1 * rand_vals.x );
  float r = 4 + rand_vals.y;
  float3 pos = r * float3( cos(angle), 0, sin(angle) );
  pos.y = 4 + rand_vals.y;
  instances[ id ].pos = pos;
  instances[ id ].scale = 0.02f;
}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(
  in VS_INPUT input
, in uint InstanceID : SV_InstanceID
, StructuredBuffer<TInstance> instances : register(t0)
)
{
  TInstance instance = instances[ InstanceID ];
  float3 p = instance.pos;
  float scale = instance.scale;
  float4x4 mtx = { scale, 0, 0, 0 
                 , 0, scale, 0, 0
                 , 0, 0, scale, 0
                 , p.x, p.y, p.z, 1 };
  float4x4 newWorld = mul( mtx, World );
  return runObjVS( input, newWorld );
}

