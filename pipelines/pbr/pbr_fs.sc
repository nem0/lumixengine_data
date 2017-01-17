$input v_wpos, v_texcoord0 // in...

#include "common.sh"


SAMPLER2D(u_gbuffer0, 15);
SAMPLER2D(u_gbuffer1, 14);
SAMPLER2D(u_gbuffer2, 13);
SAMPLER2D(u_gbuffer_depth, 12);
SAMPLERCUBE(u_irradiance_map, 11);
SAMPLERCUBE(u_radiance_map, 10);
SAMPLER2D(u_texShadowmap, 9);


uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_fogParams;


void main()
{
	float f0 = 0.04;
	
	vec4 gbuffer1_val = texture2D(u_gbuffer1, v_texcoord0);
	vec4 gbuffer2_val = texture2D(u_gbuffer2, v_texcoord0);
	vec3 normal = normalize(gbuffer1_val.xyz * 2 - 1);
	vec4 albedo = texture2D(u_gbuffer0, v_texcoord0);
	float roughness = albedo.w;
	float metallic = gbuffer1_val.w;
	
	vec3 wpos = getViewPosition(u_gbuffer_depth, u_camInvViewProj, v_texcoord0);

	vec4 camera_wpos = mul(u_camInvView, vec4(0, 0, 0, 1));
	vec3 view = normalize(camera_wpos.xyz - wpos);
	
	vec4 specular_color = (f0 - f0 * metallic) + albedo * metallic;
	vec4 diffuse_color = albedo - albedo * metallic;
	
	float ndotv = saturate(dot(normal, view));
	vec3 direct_diffuse;
	vec3 direct_specular;
	PBR_ComputeDirectLight(normal, -u_lightDirFov.xyz, view, u_lightRgbAttenuation.rgb, 0.24, roughness, direct_diffuse, direct_specular);

	vec3 indirect_diffuse = PBR_ComputeIndirectDiffuse(u_irradiance_map, normal, diffuse_color.rgb);
	vec3 rv = reflect(-view.xyz, normal.xyz);
	vec3 indirect_specular = PBR_ComputeIndirectSpecular(u_radiance_map, specular_color.rgb, roughness, ndotv, rv);
	
	float ndotl = -dot(normal, u_lightDirFov.xyz);
	float shadow = directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(wpos, 1), ndotl);
	float fog_factor = getFogFactor(camera_wpos.xyz / camera_wpos.w, u_fogColorDensity.w, wpos.xyz, u_fogParams);
	vec3 lighting = 
		direct_diffuse * diffuse_color.rgb * shadow + 
		direct_specular * specular_color.rgb * shadow + 
		indirect_diffuse + 
		indirect_specular +
		0
		;
	float prebaked_ao = gbuffer2_val.x;
	gl_FragColor.rgb = mix(lighting * prebaked_ao, u_fogColorDensity.rgb, fog_factor);
	gl_FragColor.w = 1;
}