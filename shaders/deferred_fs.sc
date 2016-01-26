$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_gbuffer0, 0);
SAMPLER2D(u_gbuffer1, 1);
SAMPLER2D(u_gbuffer2, 2);
SAMPLER2D(u_gbuffer_depth, 3);
SAMPLER2D(u_texShadowmap, 4);

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
	v_texcoord0.y = 1 - v_texcoord0.y; // todo
	vec3 normal = texture2D(u_gbuffer1, v_texcoord0) * 2 - 1;
	vec4 color = texture2D(u_gbuffer0, v_texcoord0);

	vec3 diffuse = calcGlobalLight(u_lightDirFov.xyz, u_lightRgbAttenuation.rgb, normal) * color.rgb;

	vec4 wpos = getViewPos(v_texcoord0);
	
	float ndotl = -dot(normal, u_lightDirFov.xyz);
	diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, wpos, ndotl); 

	vec3 ambient = u_ambientColor.rgb * color.rgb;

	vec4 view_pos = mul(u_camView, wpos);

	float fog_factor = getFogFactor(view_pos.z / view_pos.w, u_fogColorDensity.w, wpos.y, u_fogParams);
	gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
	gl_FragColor.w = 1;
}
