$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(gbuffer0, 0);
SAMPLER2D(gbuffer1, 1);
SAMPLER2D(gbuffer2, 2);
SAMPLER2D(u_texShadowmap, 3);

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbInnerR;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_lightSpecular;
uniform vec4 u_fogParams;

void main()
{
	v_texcoord0.y = 1 - v_texcoord0.y; // todo
	vec3 normal = texture2D(gbuffer1, v_texcoord0) * 2 - 1;
	vec4 color = texture2D(gbuffer0, v_texcoord0);

	vec3 diffuse = calcGlobalLight(u_lightDirFov.xyz, u_lightRgbInnerR.rgb, normal) * color.rgb;

	float ndotl = -dot(normal, u_lightDirFov.xyz);
	//diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(v_wpos, 1.0), ndotl); 

	vec3 ambient = u_ambientColor.rgb * color.rgb;
	float fog_factor = 0; // todo
	gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
	gl_FragColor.w = 1;
}
