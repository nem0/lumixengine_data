$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_gbuffer0, 15);
SAMPLER2D(u_gbuffer1, 14);
SAMPLER2D(u_gbuffer2, 13);
SAMPLER2D(u_gbuffer_depth, 12);
SAMPLER2D(u_texShadowmap, 11);

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_lightSpecular;
uniform vec4 u_fogParams;


void main()
{
	vec3 normal = texture2D(u_gbuffer1, v_texcoord0).xyz * 2 - 1;
	vec4 color = texture2D(u_gbuffer0, v_texcoord0);
	vec4 value2 = texture2D(u_gbuffer2, v_texcoord0) * 64.0;
	
	vec3 wpos = getViewPosition(u_gbuffer_depth, u_camInvViewProj, v_texcoord0);

	vec4 camera_wpos = mul(u_camInvView, vec4(0, 0, 0, 1));
	vec3 view = normalize(camera_wpos.xyz - wpos);
	
	vec4 mat_specular_shininess = vec4(value2.x, value2.x, value2.x, value2.y);
	
	
	vec3 diffuse = shadeDirectionalLight(u_lightDirFov.xyz
					, view
					, u_lightRgbAttenuation.rgb
					, u_lightSpecular.rgb
					, normal
					, mat_specular_shininess
					, vec3(1, 1, 1));
	diffuse = diffuse * color.rgb;
					
	float ndotl = -dot(normal, u_lightDirFov.xyz);
	diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(wpos, 1), ndotl); 

	vec3 ambient = u_ambientColor.rgb * color.rgb;
	float fog_factor = getFogFactor(camera_wpos.xyz / camera_wpos.w, u_fogColorDensity.w, wpos.xyz, u_fogParams);
	gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
	gl_FragColor.w = 1;
}
