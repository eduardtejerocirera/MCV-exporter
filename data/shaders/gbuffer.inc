
//--------------------------------------------------------------------------------------
struct GBuffer
{
  float3 wPos;
  float3 N;
  float3 albedo;
  float3 specular_color;
  float  roughness;
  float3 reflected_dir;
  float3 view_dir;
};

//--------------------------------------------------------------------------------------
// Macro function to return information from gBuffer
void decodeGBuffer( 
     in float2 iPosition          // Screen coords
   , out GBuffer g
   ) {

  int3 ss_load_coords = uint3(iPosition.xy, 0);

  // Recover world position coords
  float  zlinear = txGLinearDepth.Load(ss_load_coords).x;
  g.wPos = getWorldCoords(iPosition.xy, zlinear);

  // Recuperar la normal en ese pixel. Sabiendo que se
  // guardó en el rango 0..1 pero las normales se mueven
  // en el rango -1..1
  float4 N_rt = txGNormal.Load(ss_load_coords);
  g.N = decodeNormal( N_rt.xyz );
  g.N = normalize( g.N );

  // Get other inputs from the GBuffer
  float4 albedo = txGAlbedo.Load(ss_load_coords);
  // In the alpha of the albedo, we stored the metallic value
  // and in the alpha of the normal, we stored the roughness
  float  metallic = albedo.a;
         g.roughness = N_rt.a;
 
  // Apply gamma correction to albedo to bring it back to linear.
  albedo.rgb = pow(abs(albedo.rgb), 2.2f);

  // Lerp with metallic value to find the good diffuse and specular.
  // If metallic = 0, albedo is the albedo, if metallic = 1, the
  // used albedo is almost black
  g.albedo = albedo.rgb * ( 1. - metallic );

  // 0.03 default specular value for dielectric.
  g.specular_color = lerp(0.03f, albedo.rgb, metallic);

  // Eye to object
  float3 incident_dir = normalize(g.wPos - CameraPosition.xyz);
  g.reflected_dir = normalize(reflect(incident_dir, g.N));
  g.view_dir = -incident_dir;
}

