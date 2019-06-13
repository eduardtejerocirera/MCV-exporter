
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
  float4 emissive;
  float3 diffuse_color;
  float  metallic;
};

//--------------------------------------------------------------------------------------
// Macro function to return information from gBuffer
void decodeGBuffer( 
  in float2 iPosition          // Screen coords
, out GBuffer g
) 
{

  int3 ss_load_coords = uint3(iPosition.xy, 0);
  // Recover world position coords
  float  zlinear = txGLinearDepth.Load(ss_load_coords).x;
  g.wPos = getWorldCoords(iPosition.xy, zlinear);

  // Recuperar la normal en ese pixel. Sabiendo que se
  // guardó en el rango 0..1 pero las normales se mueven
  // en el rango -1..1
  float4 N_rt = txGNormal.Load(ss_load_coords);
  g.N = normalize(decodeNormal( N_rt.xyz));
  g.roughness = max(0.01,N_rt.a);

  // Get other inputs from the GBuffer
  float4 albedo = txGAlbedo.Load(ss_load_coords);
  //albedo.xyz = float3(1,0,0);
  g.albedo.rgb = albedo.rgb;//pow(albedo.rgb, 2.2);
  g.metallic = min(albedo.w,0.99);  

  //Recuperamos el Emissive
  g.emissive = txGEmissive.Load(ss_load_coords);
  //g.emissive.rgb = pow(abs(g.emissive.rgb), 2.2f);
  
  g.specular_color = lerp( 0.04, g.albedo.rgb, g.metallic);  //check reflectance https://google.github.io/filament/Filament.html#materialsystem/parameterization
  g.diffuse_color =  lerp( g.albedo.rgb, float3(0,0,0), g.metallic );

  // Eye to object
  float3 incident_dir = normalize(g.wPos - CameraPosition.xyz);
  g.reflected_dir = normalize(reflect(incident_dir, g.N));
  g.view_dir = -incident_dir;

}

