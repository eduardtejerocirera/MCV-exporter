//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
#include "common.fx"
#include "noise.inc"
#include "gbuffer.inc"
#include "pbr.inc"


//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS(
  VS_INPUT input
)
{
  // Use world from the constants uniform
  return runObjVS( input, World );
}


//--------------------------------------------------------------------------------------
// Vertex Shader for Skin, using standard vertex + skin info
//--------------------------------------------------------------------------------------
VS_OUTPUT VS_skin(
  VS_INPUT input,
  VS_SKINNING skinning
)
{
  float4x4 SkinMatrix = getSkinMtx( skinning );
  return runObjVS( input, SkinMatrix );
}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
VS_OUTPUT VS_instanced (
  VS_INPUT input,
  VS_INSTANCE_WORLD instance_data     // Stream 1
)
{
  // Use world from the instance
  float4x4 instanceWorld = getWorldOfInstance(instance_data);
  return runObjVS( input, instanceWorld );
}

//--------------------------------------------------------------------------------------
// Vertex Shader
//--------------------------------------------------------------------------------------
SHADER_CTE_BUFFER(TCtesMorph, CTE_BUFFER_SLOT_COMP_BUFFERS)
{
  float  morph_weight_target;
  float3 morph_pad3;
};

VS_OUTPUT VS_morph (
  VS_INPUT_MORPH input_morph
)
{
  float amount_of_next = morph_weight_target; //saturate( ( cos(GlobalWorldTime) + 1 ) * 0.5 );
  VS_INPUT input;
  input.Pos = input_morph.Pos * ( 1.0 - amount_of_next ) + input_morph.Pos1 * amount_of_next;
  input.N   = input_morph.N   * ( 1.0 - amount_of_next ) + input_morph.N1   * amount_of_next;
  input.Uv  = input_morph.Uv;
  input.T   = input_morph.T;
  return runObjVS( input, World );
}

void PS_common(
      VS_OUTPUT input
, out float4 o_albedo    : SV_Target0
, out float4 o_normal    : SV_Target1
, out float1 o_depth     : SV_Target2
, out float4 o_emissive  : SV_Target3
, bool use_alpha_test
)
{
  float4 albedo_color = txAlbedo.Sample(samLinear, input.Uv);
  if( use_alpha_test && albedo_color.a <= 0.2 )
    clip(-1);
  o_albedo.xyz = albedo_color.xyz * input.Color.xyz;
  // Encode Metallic factor in alpha coord
  o_albedo.a = txMetallic.Sample(samLinear, input.Uv).r;

  // Normal mapping
  float4 N_tangent_space = txNormal.Sample(samLinear, input.Uv);  // Between 0..1
  N_tangent_space.y = 1 - N_tangent_space.y;
  N_tangent_space.xyz = N_tangent_space.xyz * 2 - 1.;                           // Between -1..1

  float3 T = input.T.xyz;
  float3 B = cross(T, input.N) * input.T.w;
  float3x3 TBN = float3x3(T,B,input.N);
  float3 N = mul( N_tangent_space.xyz, TBN );   // Normal from NormalMap

  // Save roughness in the alpha coord of the N render target
  float roughness = txRoughness.Sample(samLinear, input.Uv).r;
  o_normal = encodeNormal(N, roughness);

  float3 cam2obj = input.WorldPos.xyz - CameraPosition.xyz;
  float  linear_depth = dot( cam2obj, CameraFront ) / CameraZFar;

  o_depth = linear_depth;

  o_emissive.xyz = txEmissive.Sample(samLinear, input.Uv).xyz;
  o_emissive.w = txAOC.Sample(samLinear, input.Uv).x;
}

void PS_switch(
      VS_OUTPUT input
, out float4 o_albedo : SV_Target0
, out float4 o_normal : SV_Target1
, out float1 o_depth  : SV_Target2
, out float4 o_emissive  : SV_Target3
)
{
  o_albedo = o_emissive = input.Color;//float4(0.5,0.5,0.5,1) * txAlbedo.Sample(samLinear, input.Uv);
}

void PS_lava(
      VS_OUTPUT input
, out float4 o_albedo : SV_Target0
, out float4 o_normal : SV_Target1
, out float1 o_depth  : SV_Target2
, out float4 o_emissive  : SV_Target3
)
{

  //lerp material , emissive color * emissive factor, algun noise
  //le sube los negros a la mitad aprox
  //usa el noise como un bumpmap para el material

  float4 albedo_color = txAlbedo.Sample(samLinear, input.Uv);
  o_albedo.xyz = albedo_color.xyz * input.Color.xyz;
  // Encode Metallic factor in alpha coord
  o_albedo.a = txMetallic.Sample(samLinear, input.Uv).r;

  // Normal mapping
  float4 N_tangent_space = txNormal.Sample(samLinear, input.Uv);  // Between 0..1
  N_tangent_space.y = 1 - N_tangent_space.y;
  N_tangent_space.xyz = N_tangent_space.xyz * 2 - 1.;                           // Between -1..1

  float3x3 TBN = computeTBN( input.N, input.T );
  float3 N = mul( N_tangent_space.xyz, TBN );   // Normal from NormalMap

  // Save roughness in the alpha coord of the N render target
  float roughness = txRoughness.Sample(samLinear, input.Uv).r;
  o_normal = encodeNormal(N, roughness);

  float3 cam2obj = input.WorldPos.xyz - CameraPosition.xyz;
  float  linear_depth = dot( cam2obj, CameraFront ) / CameraZFar;

  o_depth = linear_depth;

  //o_emissive.xyz = txEmissive.Sample(samLinear, input.Uv).xyz;
  o_emissive.w = txAOC.Sample(samLinear, input.Uv).x;


  /* vec2 st = gl_FragCoord.xy/u_resolution.xy;
    st.x *= u_resolution.x/u_resolution.y;
    vec3 color = vec3(0.0);
    vec2 pos = vec2(st*3.);

    float DF = 0.0;

    // Add a random position
    float a = 0.0;
    vec2 vel = vec2(u_time*.1);
    DF += snoise(pos+vel)*.25+.25;

    // Add a random position
    a = snoise(pos*vec2(cos(u_time*0.15),sin(u_time*0.1))*0.1)*3.1415;
    vel = vec2(cos(a),sin(a));
    DF += snoise(pos+vel)*.25+.25;

    color = vec3( smoothstep(.7,.75,fract(DF)) );

    gl_FragColor = vec4(1.0-color,1.0);*/


  float NdotUp = dot(N, float3(0,1,0));
  float3 left = cross(N, float3(0,1,0));
  float horizontal = (1 - abs(NdotUp));

  float a = 0;
  float3 pos = input.WorldPos * .3;
  float time = GlobalWorldTime;
  float3 vel1 = float3(0.005,0.1,0.005) * time * .5;
  float3 vel2 = float3(0.005,0.4,0.005) * time * 1;
  float3 vel = lerp(vel1,vel2,horizontal);
  float df = snoise( pos + vel ) *.25 + .25;

  time *= .001;
  a = snoise( pos * float3(cos(time), sin(time),  sin(time)) ) * 3.1415;


  vel = lerp(float3(cos(a),sin(a*2),1), vel, horizontal);
  df += snoise( pos + vel )*.25+.25;

  vel = lerp(float3(cos(df),sin(df*2),1), vel, horizontal);
  df += snoise( pos + vel )*.01+.25;
  
  //a = smoothstep(.75,.75,frac(df * lerp(6,4,horizontal)));
  //a = smoothstep(.5,.5,frac(df * lerp(6,4,horizontal)));

  //o_albedo.xyz = a;// input.Colo(pow(float3( a,a,a ), 1)) + 0.1;// * input.Color;
  o_emissive.xyz = (o_albedo.xyz + (1 - a))*o_albedo.xyz;// input.Colo(pow(float3( a,a,a ), 1)) + 0.1;// * input.Color;
  //o_emissive.xyz = pow(a*1.1,1./2.);//pow(float3( a,a,a ), 2.2) * input.Color;
  //o_emissive.xyz += a* o_albedo.xyz;//pow(float3( a,a,a ), 2.2) * input.Color;
  //o_emissive.xyz *= 1 - smoothstep(0.1,0.5,snoise( input.WorldPos * .1 + float3(0.005,0,0.005) * time * 2 ) *.25 + .25);
}

void PS_test(
      VS_OUTPUT input
, out float4 o_albedo : SV_Target0
, out float4 o_normal : SV_Target1
, out float1 o_depth  : SV_Target2
, out float4 o_emissive  : SV_Target3
)
{
  float4 albedo_color = txAlbedo.Sample(samLinear, input.Uv);
  o_albedo.xyz = float3(1,0,0);//albedo_color.xyz;// * input.Color;
  // Encode Metallic factor in alpha coord
  o_albedo.a = input.Color.g;//txMetallic.Sample(samLinear, input.Uv).r;

  // Normal mapping
  float4 N_tangent_space = txNormal.Sample(samLinear, input.Uv);  // Between 0..1
  N_tangent_space.y = 1 - N_tangent_space.y;
  N_tangent_space.xyz = N_tangent_space.xyz * 2 - 1.;                           // Between -1..1

  float3x3 TBN = computeTBN( input.N, input.T );
  float3 N = mul( N_tangent_space.xyz, TBN );   // Normal from NormalMap
  
  // Save roughness in the alpha coord of the N render target
  float roughness = input.Color.r;//txRoughness.Sample(samLinear, input.Uv).r;
  o_normal = encodeNormal(N, roughness);

  float3 cam2obj = input.WorldPos.xyz - CameraPosition.xyz;
  float  linear_depth = dot( cam2obj, CameraFront ) / CameraZFar;

  o_depth = linear_depth;

  o_emissive.xyz = input.Color.b;//txEmissive.Sample(samLinear, input.Uv).xyz;
  o_emissive.w = txAOC.Sample(samLinear, input.Uv).x;
}

void PS( VS_OUTPUT input
, out float4 o_albedo     : SV_Target0
, out float4 o_normal     : SV_Target1
, out float1 o_depth      : SV_Target2
, out float4 o_emissive   : SV_Target3
) {
  PS_common( input, o_albedo, o_normal, o_depth, o_emissive, false );
}

void PS_alpha( VS_OUTPUT input
, out float4 o_albedo     : SV_Target0
, out float4 o_normal     : SV_Target1
, out float1 o_depth      : SV_Target2
, out float4 o_emissive   : SV_Target3
) {
  PS_common( input, o_albedo, o_normal, o_depth, o_emissive, true );
}

//--------------------------------------------------------------------------------------
void PS_gbuffer_mix(
  VS_OUTPUT input
, out float4 o_albedo     : SV_Target0
, out float4 o_normal     : SV_Target1
, out float1 o_depth      : SV_Target2
, out float4 o_emissive   : SV_Target3 
) {
  // This is different -----------------------------------------
  float2 iTex0 = input.Uv * 2;
  float2 iTex1 = input.Uv;

  float4 weight_texture_boost = txMixBlendWeights.Sample(samLinear, iTex1); 

  float4 albedoR = txAlbedo.Sample(samLinear, iTex0);
  float4 albedoG = txAlbedo1.Sample(samLinear, iTex0);
  float4 albedoB = txAlbedo2.Sample(samLinear, iTex0);

  // Use the alpha of the albedo as heights + texture blending extra weights + material ctes extra weights (imgui)
  float w1, w2, w3;
  computeBlendWeights( albedoR.a + mix_boost_r + weight_texture_boost.r
                     , albedoG.a + mix_boost_g + weight_texture_boost.g
                     , albedoB.a + mix_boost_b + weight_texture_boost.b
                     , w1, w2, w3 );

  // Use the weight to 'blend' the albedo colors
  float4 albedo = albedoR * w1 + albedoG * w2 + albedoB * w3;
  o_albedo.xyz = albedo.xyz;

  // Mix the normal
  float3 normalR = txNormal.Sample(samLinear, iTex0).xyz * 2.0 - 1.0;
  float3 normalG = txNormal1.Sample(samLinear, iTex0).xyz * 2.0 - 1.0;
  float3 normalB = txNormal2.Sample(samLinear, iTex0).xyz * 2.0 - 1.0;
  float3 normal_color = normalR * w1 + normalG * w2 + normalB * w3; 
  float3x3 TBN = computeTBN( input.N, input.T );

  // Normal map comes in the range 0..1. Recover it in the range -1..1
  float3 wN = mul( normal_color, TBN );
  float3 N = normalize( wN );

  // Missing: Do the same with the metallic & roughness channels
  // ...

  // Possible plain blending without heights
  //o_albedo.xyz = lerp( albedoB.xyz, albedoG.xyz, weight_texture_boost.y );
  //o_albedo.xyz = lerp( o_albedo.xyz, albedoR.xyz, weight_texture_boost.x );

  //o_albedo.xyz = float3( iTex1.xy, 0 );   // Show the texture coords1

  //o_albedo.xyz = weight_texture_boost.xyz;  // Show the extra weight textures

  o_albedo.a = txMetallic.Sample(samLinear, iTex0).r;

  // This is the same -----------------------------------------
  // Save roughness in the alpha coord of the N render target
  float roughness = txRoughness.Sample(samLinear, iTex0).r;
  o_normal = encodeNormal( N, roughness );

  // Compute the Z in linear space, and normalize it in the range 0...1
  // In the range z=0 to z=zFar of the camera (not zNear)
  float3 cam2obj = input.WorldPos.xyz - CameraPosition.xyz;
  float  linear_depth = dot( cam2obj, CameraFront ) / CameraZFar;
  o_depth = linear_depth;
}


// -------------------------------------------------
// The output of the deferred before the postFX
float4 PS_GBuffer_Resolve( 
  float4 iPosition   : SV_POSITION,
  float2 iUV         : TEXCOORD0
  ) : SV_Target
{
  int3 ss_load_coords = uint3(iPosition.xy, 0);

  //float4 albedo_color = txGAlbedo.Load(ss_load_coords);
  //float  linear_depth = txGLinearDepth.Sample(samLinear, iUV).x;
  //return float4( 0.5, 1, 0, 1);
  float4 acc_light = txAccLights.Load(ss_load_coords);
  float4 emissive_light = txGEmissive.Load(ss_load_coords) * 2.1;
  
  return acc_light + emissive_light;
}


// -------------------------------------------------
float4 PS_Ambient(
  in float4 iPosition : SV_Position
, in float2 iUV : TEXCOORD0
) : SV_Target
{

  // Declare some float3 to store the values from the GBuffer
  GBuffer g;
  decodeGBuffer( iPosition.xy, g );

  float NdV = clamp( dot(g.N, g.view_dir), 0 , 0.98);

  float3 f0 = g.specular_color;
  float f90 = 1; //assuming

  
  // remapping and linearization of clear coat 
  float clearCoatFactor = 1.0;
  float clearCoatRoughness = 1.0;
  clearCoatRoughness = lerp(0.089, 0.6, clearCoatRoughness);
  float clearCoatAlpha = clearCoatRoughness * clearCoatRoughness;

  f0 = lerp(f0, f0ClearCoatToSurface(f0), clearCoatFactor);
  // remap roughness: the base layer must be at least as rough as the clear coat layer
	g.roughness = clearCoatFactor > 0.0 ? max(g.roughness, clearCoatRoughness) : g.roughness;


  //PREM
  float  a = g.roughness * g.roughness;
  float  lodLevel = g.roughness * 8.0;
  float3 radiance = txEnvironmentMap.SampleLevel(samLinear, g.reflected_dir, lodLevel).xyz; 
  
  //Irradiance
  float3 irradiance = txIrradianceMap.Sample(samLinear, g.N).xyz;

  //Multiple scattering - paper 
  float nr = 1. - g.roughness;

  float3 Fr = max( float3( nr, nr, nr ), f0) - f0;
  float3 kS = f0 + Fr * pow( 1.0 - NdV, 5.0 );
  //float3 kS = F0 + (f90 - F0) * pow(1.0 - NdV, 5.0);

  float2 f_ab = txDFG.Sample(samLinear, float2( NdV, 1.0 - g.roughness )).xy; //estaria bien que la textura DFG estubiese en 16bit por componente //uso 1-roughness porque esta del reves la textura
  float3 FssEss = kS * f_ab.x + f_ab.y;

  float Ess = f_ab.x + f_ab.y;
  float Ems = 1.0 - Ess;
  
  float3 Favg = f0 + (1.0 - f0) / PI;
  
  float3 Fms = FssEss * Favg / ( 1.0 - Favg * ( 1.0 - Ess ));

  //Dielectrics
  float3 Edss = 1.0 - (FssEss + Fms * Ems);
  float3 kD = g.diffuse_color * Edss; //albedo * Edss


    // CLEAT COAT LOBE ************************

    float f0_clearCoat = 0.04;
    float  Fcc = (f0_clearCoat + (1.0 - f0_clearCoat) * pow(1.0 - NdV, 5.0)) * clearCoatFactor;
    float3 att2 = float3(1,1,1) - float3(Fcc,Fcc,Fcc);

    

  //Dielectrics

  float3 A_Fd = (Fms * Ems + kD) * irradiance;
  float3 A_Fr = FssEss * radiance;
  //float4 A = float4(FssEss * radiance + (Fms * Ems + kD) * irradiance, 1.0);

  //Conductors
  float3 B_Fd = Fms * Ems * irradiance;
  float3 B_Fr = FssEss * radiance;
  //float4 B = float4(FssEss * radiance + Fms * Ems * irradiance, 1.0);
   

  float3 Fd = lerp(A_Fd,B_Fd, g.metallic);
  Fr = lerp(A_Fr,B_Fr, g.metallic);

  // apply tint
  //Fd_i *= lerp(float3(1.0), color, material.clearCoat);
  Fr *= att2;
  Fd *= (att2 * att2);

  // apply clear coat
  
  float3 indirect = Fr + Fd;
  indirect += txEnvironmentMap.SampleLevel(samLinear, g.reflected_dir, clearCoatRoughness * 8).xyz * Fcc; 

  float4 ao = txAO.Sample( samLinear, iUV );

  return float4(indirect,1.0) * ao.x * GlobalAmbientBoost;
}

float4 PS_Ambient2(
  in float4 iPosition : SV_Position
, in float2 iUV : TEXCOORD0
) : SV_Target
{
  GBuffer g;
  decodeGBuffer( iPosition.xy, g );

  // if roughness = 0 -> I want to use the miplevel 0, the all-detailed image
  // if roughness = 1 -> I will use the most blurred image, the 8-th mipmap, If image was 256x256 => 1x1
  float mipIndex = g.roughness * g.roughness * 8.0;
  //computeLODFromRoughness(perceptualRoughness)

  float3 f0 = g.specular_color;
  float f90 = 1.0;
  //float f90 = clamp(dot(f0, 50.0 * 0.33), 0.0, 1.0);

  float3 V = normalize(CameraPosition - g.wPos);
  float NdotV = clamp( dot(g.N,V), 0 , 0.98);

  //Irradiance
  float3 Ld = txIrradianceMap.Sample(samLinear, g.N).xyz * g.albedo;
  //Ld = pow(abs(Ld), 2.2);

  //PREM
  float3 Lld = txEnvironmentMap.SampleLevel(samLinear, g.reflected_dir, mipIndex).xyz; 
  //Lld = pow(abs(Lld), 2.2);

  //DFG
  float2 Ldfg = txDFG.Sample(samLinear, float2( NdotV, 1 - sqrt(max(0.089,g.roughness)) )).xy; //estaria bien que la textura DFG estubiese en 16bit por componente
  float3 Lr =  (f0 * Ldfg.x + f90 * Ldfg.y) * Lld;
  float4 ao = txAO.Sample( samLinear, iUV);
  
  return float4( (Ld + Lr) * ao.x, 1) ;
}


// ----------------------------------------
// Passthrough for the lights geometry
void VS_pass(
  in float4 iPos : POSITION
, out float4 oPos : SV_POSITION
) {
  float4 world_pos = mul(iPos, World);
  oPos = mul(world_pos, ViewProjection);
}

// ----------------------------------------
void VS_skybox( 
  in float4 iPosition  : POSITION 
, in float4 iColor     : COLOR0 
, out float4 oPosition : SV_Position 
) {
  // Convert the range 0..1 from iPosition to -1..1 to match the homo spacew
  oPosition = float4(iPosition.x * 2 - 1., 1 - iPosition.y * 2, 1, 1);
}

// --------------------------------------------------------
float4 PS_skybox( in float4 iPosition : SV_Position ) : SV_Target
{
  float3 view_dir = mul( float4( iPosition.xy, 1, 1 ), CameraScreenToWorld ).xyz;
  float4 skybox_color = txEnvironmentMap.Sample(samLinear, view_dir);
  return pow(float4(skybox_color.xyz,1) * max(1,GlobalAmbientBoost), 2.2);
}
// --------------------------------------------------------


// --------------------------------------------------------
float4 shade( float4 iPosition, bool use_shadows ) {

  // Declare some float3 to store the values from the GBuffer
  GBuffer g;
  decodeGBuffer( iPosition.xy, g );

  // Shadow factor entre 0 (totalmente en sombra) y 1 (no ocluido)
  float shadow_factor = use_shadows ? getShadowFactor( g.wPos ) : 1.; 

  // From wPos to Light
  float3 light_dir_full = LightPosition.xyz - g.wPos;
  float  distance_to_light = length( light_dir_full );
  float3 light_dir = light_dir_full / distance_to_light;

  //Light attenuation factor
  float att = 1. - saturate( distance_to_light / LightRadius );

  float  a   = max(0.001, g.roughness * g.roughness);
  float3 h   = normalize(light_dir + g.view_dir); // half vector
  float3 f0 = g.specular_color;

  float  NdV = saturate(dot(g.N, g.view_dir));
  float  NdL = saturate(dot(g.N, light_dir));
  float  NdH = saturate(dot(g.N, h));
  
  float  LdV = saturate(dot(light_dir,  g.view_dir));
  float  LdH = saturate(dot(light_dir,  h));
  float  VdH = saturate(dot(g.view_dir, h));

  float  D = NDF_GGX(a, NdH);
  float3 F = F_Schlick(LdH, f0);
  float  G = Geometric_Smith_Schlick_GGX_(a, NdV, NdL);

  //Difuse BSDF Term - Disney Burley
  float3 Fd = g.diffuse_color * Fd_Burley(NdV, NdL, LdH, g.roughness);

  //Specular BSDF Term - only BRDF, no BTDF, no BSSDF
  float3 Fr = D * F * G;
         Fr /= (4.0 * NdL * NdV + 0.0001);      

  
  //Material interaction contribution
  float3 final_color = Fd + Fr;

  //Rim light
  float3 _RimColor = float3(1,1,1);
  float _RimFalloff = 0;
  float _RimBack = 0.5;
  float _RimPower = 1;
  float3 rimLight = _RimColor * saturate(smoothstep(-.3, 1, dot(g.N, light_dir)) - NdL) * (1-NdV);
  
  
  //float3 rimLight = _RimColor * saturate(step(NdL - dot(g.N, light_dir), 0.1));// * _RimPower * smoothstep(_RimFalloff, 1.0, 1 - dot(g.N, g.view_dir) ) * smoothstep(_RimBack, 1.0, dot(g.N, light_dir));
  //rimLight =  NdL - 1 - ((NdL * .5 + .5) - smoothstep(0, 1,dot(g.N, light_dir) * .5 + .5))*2 - 0.5;//NdL - smoothstep(0, 1, dot(g.N, light_dir) * .5 + .5) * 10;
  //Light properties contribution
  final_color *= att * LightColor.xyz * ( shadow_factor * NdL );// saturate( smoothstep( 0, 1, dot(g.N, g.view_dir))  );
  //final_color = NdL + rimLight;//saturate(NdL) * att * LightColor.xyz * shadow_factor ;// saturate( smoothstep( 0, 1, dot(g.N, g.view_dir))  );

  return float4(final_color,1);
}

// -------------------------------------------------
float4 PS_point_lights(
  in float4 iPosition : SV_Position
) : SV_Target
{
  return shade( iPosition, false );
}

float4 PS_dir_lights(
  in float4 iPosition : SV_Position
) : SV_Target
{
  GBuffer g;
  decodeGBuffer( iPosition.xy, g );
  float4 PosLightProjection = mul(float4(g.wPos, 1), LightViewProjOffset);
  float3 PosLightHomoSpace = PosLightProjection.xyz / PosLightProjection.w;

  return shade( iPosition, true ) * txProjector.Sample(samBorderColor, PosLightHomoSpace.xy);
}


