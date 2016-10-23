$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2
	
#include "common.sh"

SAMPLER2D(u_texNormal, 0);
SAMPLERCUBE(u_texReflection, 1);

uniform vec4 u_normalStrength;
uniform vec4 u_fresnelPower;
uniform vec4 u_eta;
uniform vec4 u_time;
uniform vec4 u_specPower;
uniform vec4 u_textureScale;
uniform vec3 u_waterColor;
uniform vec3 u_specColor;
uniform vec4 u_lightDirFov; 
uniform vec4 u_flowDir; 

#define normal_strength u_normalStrength.x
#define fresnel_power u_fresnelPower.x
#define eta u_eta.x
#define spec_power u_specPower.x
#define texture_scale u_textureScale.x
#define time u_time.x
#define flow_dir u_flowDir.xy

void main()
{   
	mat3 tbn = mat3(
		normalize(v_tangent),
		normalize(v_normal),
		normalize(v_bitangent)
		);
	tbn = transpose(tbn);
	vec2 tc = v_texcoord0 * texture_scale + flow_dir * time * 0.05;
	
	vec3 wnormal0 = texture2D(u_texNormal, tc).xzy * 2.0 - 1.0;
	vec3 wnormal1 = texture2D(u_texNormal, vec2(1, 1) - tc).xzy * 2.0 - 1.0;
	
	float t = time * 0.3 % 1;
	vec3 wnormal = mix(wnormal0, wnormal1, abs( 0.5 - t ) / 0.5);
	
	wnormal = mix(vec3(0, 1, 0), wnormal, normal_strength);
	wnormal = normalize(mul(tbn, wnormal));
	
	vec3 reflection = normalize(reflect(-v_view, wnormal));
	vec3 refl_color = textureCube(u_texReflection, reflection).rgb;
	
	//vec3 refraction = refract(-v_view, wnormal, eta);
	vec3 refr_color = u_waterColor.rgb;
	
	vec3 halfvec = normalize(mix(-u_lightDirFov.xyz, normalize(v_view), 0.5));
	float spec_strength = pow(dot(halfvec, wnormal), spec_power);
	vec3 spec_color = u_specColor.rgb * spec_strength;
	
	float fresnel = eta + (1.0 - eta) * pow(max(0.0, 1.0 - dot(normalize(v_view), wnormal)), fresnel_power);
	vec3 color = mix(refr_color, refl_color, fresnel);
	gl_FragColor = vec4(color + spec_color, 1);
}
