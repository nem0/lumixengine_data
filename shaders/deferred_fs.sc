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
uniform mat4 u_camInvViewProj;
uniform mat4 u_camView;
uniform mat4 u_camInvView;



vec4 getViewPos(vec2 texCoord)
{
	float z = texture2D(u_gbuffer_depth, texCoord).r;
	#if BGFX_SHADER_LANGUAGE_HLSL
		z = z;
	#else
		z = z * 2.0 - 1.0;
	#endif // BGFX_SHADER_LANGUAGE_HLSL
	vec4 posProj = vec4(texCoord * 2 - 1, z, 1.0);
	#if BGFX_SHADER_LANGUAGE_HLSL
		posProj.y = -posProj.y;
	#endif // BGFX_SHADER_LANGUAGE_HLSL
	
	vec4 posView = mul(u_camInvViewProj, posProj);
	
	posView /= posView.w;
	return posView;
}

void main()
{
	vec3 normal = texture2D(u_gbuffer1, v_texcoord0) * 2 - 1;
	vec4 color = texture2D(u_gbuffer0, v_texcoord0);
	vec4 value2 = texture2D(u_gbuffer2, v_texcoord0) * 64.0;
	
	vec4 wpos = getViewPos(v_texcoord0);

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
	diffuse = diffuse * color;
					
					
	float ndotl = -dot(normal, u_lightDirFov.xyz);
	diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, wpos, ndotl); 

	vec3 ambient = u_ambientColor.rgb * color.rgb;
	float fog_factor = getFogFactor(camera_wpos.xyz / camera_wpos.w, u_fogColorDensity.w, wpos.xyz, u_fogParams);
	gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
	gl_FragColor.w = 1;
}
