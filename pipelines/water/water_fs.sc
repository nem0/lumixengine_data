$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2
	
#include "common.sh"

SAMPLER2D(u_texNormal, 0);
SAMPLERCUBE(u_texReflection, 1);
SAMPLER2D(u_texFoam, 2);
SAMPLER2D(u_texNoise, 3);

SAMPLER2D(u_gbuffer_depth, 13);
SAMPLER2D(u_gbuffer1, 14);
SAMPLER2D(u_gbuffer0, 15);

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
uniform vec4 u_fullColorDepth; 

#define normal_strength u_normalStrength.x
#define fresnel_power u_fresnelPower.x
#define eta u_eta.x
#define spec_power u_specPower.x
#define texture_scale u_textureScale.x
#define time u_time.x
#define flow_dir u_flowDir.xy
#define fullColorDepth u_fullColorDepth.x

vec3 getReflectionColor(vec3 view, vec3 normal)
{
	vec3 reflection = normalize(reflect(-view, normal));
	return textureCube(u_texReflection, reflection).rgb;
}

vec3 getRefractionColor(vec3 wpos, vec3 view, vec3 normal, float wave)
{
	vec3 screen_uv = getScreenCoord(wpos);
	float depth = texture2D(u_gbuffer_depth, screen_uv.xy * 0.5 + 0.5).x;
	float depth_diff = toLinearDepth(screen_uv.z) - toLinearDepth(depth) + wave;
	vec3 refraction = refract(-view, normal, eta);
	vec2 refr_uv = screen_uv.xy * 0.5 + 0.5;
	refr_uv += refraction.xz * saturate(depth_diff * 0.1);
	vec3 refr_color = toLinear(texture2D(u_gbuffer0, refr_uv).rgb);
	return mix(u_waterColor.rgb, refr_color, saturate(1 - depth_diff / fullColorDepth));
}

vec3 getSurfaceNormal(vec2 uv)
{
	float noise_t = texture2D(u_texNoise, 1 - uv);
	vec2 tc0 = uv * texture_scale + flow_dir * time;
	#if 0
	vec2 tc1 = uv * texture_scale + flow_dir * (time * (1 + noise_t * 0.2));
	#else
	vec2 tc1 = uv * texture_scale + flow_dir * (time + noise_t * 0.1);
	#endif
	
	vec3 wnormal0 = (texture2D(u_texNormal, tc0).xzy + texture2D(u_texNormal, tc1*2.7).xzy) - 1.0;
	vec3 wnormal1 = (texture2D(u_texNormal, vec2(0.5, 0.5) - tc1).xzy + texture2D(u_texNormal, (vec2(0.5, 0.5) - tc1)*2.3).xzy) - 1.0;
	
	float noise = texture2D(u_texNoise, uv).x;
	float t = (time * 0.3 + noise*2) % 1;
	vec3 wnormal = mix(wnormal0, wnormal1, abs( 0.5 - t ) / 0.5);
	
	return mix(vec3(0, 1, 0), wnormal, normal_strength);
}

void main()
{   
	mat3 tbn = mat3(
		normalize(v_tangent),
		normalize(v_normal),
		normalize(v_bitangent)
		);
	tbn = transpose(tbn);
	vec3 wnormal = getSurfaceNormal(v_texcoord0.xy);
	wnormal = normalize(mul(tbn, wnormal));

	float wave = (cos(time + length(v_wpos)*0.5)) * 0.2 - 0.2;
	vec3 screen_uv = getScreenCoord(v_wpos);
	float depth = texture2D(u_gbuffer_depth, screen_uv.xy * 0.5 + 0.5).x;
	float depth_diff = toLinearDepth(screen_uv.z) - toLinearDepth(depth) + wave;

	if(depth_diff * 2 < 0.35)
	{
		wnormal = texture2D(u_gbuffer1, screen_uv.xy * 0.5 + 0.5).xyz * 2 - 1;	
		wnormal = mix(vec3(0, 1, 0), wnormal, normal_strength);
	}
	
	vec3 refl_color = getReflectionColor(v_view, wnormal);
	vec3 refr_color = getRefractionColor(v_wpos, v_view, wnormal, wave);
	
	vec3 halfvec = normalize(mix(-u_lightDirFov.xyz, normalize(v_view), 0.5));
	float spec_strength = pow(dot(halfvec, wnormal), spec_power);
	vec3 spec_color = u_specColor.rgb * spec_strength;
	
	float fresnel = eta + (1.0 - eta) * pow(max(0.0, 1.0 - dot(normalize(v_view), wnormal)), fresnel_power);
	vec3 color = mix(refr_color, refl_color, fresnel);
	#ifdef FOAM_TEXTURE

		vec3 foam0 = texture2D(u_texFoam, v_texcoord0 * texture_scale).rgb;
		vec3 foam1 = texture2D(u_texFoam, (1-v_texcoord0) * texture_scale).rgb;
		
		color = color + mix(foam0, foam1, 0.5) * saturate(0.35-abs(0.35 - depth_diff * 2));
	#endif
	gl_FragColor = vec4(color + spec_color, 1);
}
