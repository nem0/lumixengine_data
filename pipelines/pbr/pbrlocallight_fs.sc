$input v_wpos, v_texcoord0, v_view, v_pos_radius, v_color_attn, v_dir_fov, v_specular // in...

#include "common.sh"


SAMPLER2D(u_gbuffer0, 15);
SAMPLER2D(u_gbuffer1, 14);
SAMPLER2D(u_gbuffer2, 13);
SAMPLER2D(u_gbuffer_depth, 12);
#ifdef HAS_SHADOWMAP
	SAMPLER2D(u_texShadowmap, 11);
	uniform mat4 u_shadowmapMatrices[4];
#endif
	
uniform vec4 u_fogColorDensity; 
uniform vec4 u_fogParams;



void main()
{
	float f0 = 0.04;

	vec3 screen_coord = getScreenCoord(v_wpos);
	vec4 gbuffer1_val = texture2D(u_gbuffer1, screen_coord.xy * 0.5 + 0.5);
	vec4 gbuffer2_val = texture2D(u_gbuffer2, screen_coord.xy * 0.5 + 0.5);
	vec3 normal = normalize(gbuffer1_val.xyz * 2 - 1);
	vec4 albedo = texture2D(u_gbuffer0, screen_coord.xy * 0.5 + 0.5);
	float roughness = albedo.w;
	float metallic = gbuffer1_val.w;

	vec3 wpos = getViewPosition(u_gbuffer_depth, u_camInvViewProj, screen_coord.xy * 0.5 + 0.5);
	
	vec3 diff;
	vec3 spec;
	vec3 view = normalize(v_view);
	vec3 light_dir = normalize(v_pos_radius.xyz - wpos.xyz);
	PBR_ComputeDirectLight(normal, light_dir, view, v_color_attn.rgb, f0, roughness, diff, spec);
/*	float ndotl = -dot(normal, v_dir_fov.xyz);
	vec3 view = normalize(v_view);
	vec3 diffuse = color.rgb * calcLight(v_dir_fov
		, wpos
		, normal
		, view
		, screen_coord.xy
		, v_pos_radius.xyz
		, v_pos_radius.w
		, v_color_attn.xyz
		, v_color_attn.w
		, v_specular.xyz); 
	#ifdef HAS_SHADOWMAP
		diffuse = diffuse * pointLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(wpos, 1.0), v_dir_fov.w); 
	#endif
*/
	vec3 lp = v_pos_radius.xyz - wpos;
	float dist = length(lp);
	float attn = pow(max(0, 1 - dist / v_pos_radius.w), v_color_attn.w);		
	vec4 specular_color = (f0 - f0 * metallic) + albedo * metallic;
	vec4 diffuse_color = albedo - albedo * metallic;
	gl_FragColor.xyz =  attn * (diff * diffuse_color.rgb + spec * specular_color.rgb);
	gl_FragColor.w = 1;
}
