$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2
	
#include "common.sh"

SAMPLER2D(u_texNormal, 0);
SAMPLERCUBE(u_texReflection, 1);
SAMPLER2D(u_texFoam, 2);
SAMPLER2D(u_texNoise, 3);

SAMPLER2D(u_texShadowmap, 11);
SAMPLER2D(u_gbuffer_depth, 12);
SAMPLER2D(u_gbuffer2, 13);
SAMPLER2D(u_gbuffer1, 14);
SAMPLER2D(u_gbuffer0, 15);

uniform vec4 u_fogColorDensity; 
uniform vec4 u_fogParams;
uniform vec4 u_ambientColor;
uniform mat4 u_shadowmapMatrices[4];
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
uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_lightSpecular;

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


vec3 deferred(vec2 screen_uv)
{
	vec3 normal = texture2D(u_gbuffer1, screen_uv).xyz * 2 - 1;
	vec4 color = texture2D(u_gbuffer0, screen_uv);
	vec4 value2 = texture2D(u_gbuffer2, screen_uv) * 64.0;
	
	vec3 wpos = getViewPosition(u_gbuffer_depth, u_camInvViewProj, screen_uv);

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
	//diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(wpos, 1), ndotl); 

	vec3 ambient = u_ambientColor.rgb * color.rgb;
	float fog_factor = getFogFactor(camera_wpos.xyz / camera_wpos.w, u_fogColorDensity.w, wpos.xyz, u_fogParams);
	return mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
}


vec3 getRefractionColor(vec3 wpos, vec3 view, vec3 normal, float wave)
{
	vec3 screen_uv = getScreenCoord(wpos);
	float depth = texture2D(u_gbuffer_depth, screen_uv.xy * 0.5 + 0.5).x;
	float depth_diff = toLinearDepth(screen_uv.z) - toLinearDepth(depth) + wave;
	vec3 refraction = refract(-view, normal, eta);
	vec2 refr_uv = screen_uv.xy * 0.5 + 0.5;
	refr_uv += refraction.xz * saturate(depth_diff * 0.1);
	
	vec3 refr_color = deferred(refr_uv);
	return mix(u_waterColor.rgb, refr_color, saturate(1 - depth_diff / fullColorDepth));
}

vec3 getSurfaceNormal(vec2 uv)
{
	float noise_t = texture2D(u_texNoise, 1 - uv).x;
	vec2 tc0 = uv * texture_scale + flow_dir * time;
	#if 0
		vec2 tc1 = uv * texture_scale + flow_dir * (time * (1 + noise_t * 0.2));
	#else
		vec2 tc1 = uv * texture_scale + flow_dir * (time + noise_t * 0.1);
	#endif
	
	vec3 wnormal0 = (texture2D(u_texNormal, tc0).xzy + texture2D(u_texNormal, tc1*2.7).xzy) - 1.0;
	vec3 wnormal1 = (texture2D(u_texNormal, vec2(0.5, 0.5) - tc1).xzy + texture2D(u_texNormal, (vec2(0.5, 0.5) - tc1)*2.3).xzy) - 1.0;
	
	float noise = texture2D(u_texNoise, uv).x;
	float t = mod((time * 0.3 + noise*2), 1);
	vec3 wnormal = mix(wnormal0, wnormal1, abs( 0.5 - t ) / 0.5);
	
	return mix(vec3(0, 1, 0), wnormal, normal_strength);
}


void main()
{   
	const float WAVE_HEIGHT = 0.1;
	const float WAVE_FREQUENCY = 1;

	const float FOAM_DEPTH = 0.2;
	const float FOAM_TEXTURE_SCALE = 5;
	const float FOAM_WIDTH = 1;
	
	mat3 tbn = mat3(
		normalize(v_tangent),
		normalize(v_normal),
		normalize(v_bitangent)
		);
	tbn = transpose(tbn);
	vec3 wnormal = getSurfaceNormal(v_texcoord0.xy);
	wnormal = normalize(mul(tbn, wnormal));

	float noise = texture2D(u_texNoise, v_texcoord0*10).x;
	float wave = cos(time * WAVE_FREQUENCY + length(v_wpos)*0.5) * WAVE_HEIGHT - WAVE_HEIGHT - WAVE_HEIGHT * noise;
	vec3 screen_uv = getScreenCoord(v_wpos);
	float depth = texture2D(u_gbuffer_depth, screen_uv.xy * 0.5 + 0.5).x;
	float depth_diff = toLinearDepth(screen_uv.z) - toLinearDepth(depth) + wave;

	if(depth_diff < FOAM_DEPTH)
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

	fresnel *= saturate((depth_diff - wave)*10); 
	
	vec3 color = mix(refr_color, refl_color, fresnel);
	#ifdef FOAM_TEXTURE
		vec3 foam = texture2D(u_texFoam, v_texcoord0 * texture_scale * FOAM_TEXTURE_SCALE).rgb;
		color = color + foam * saturate(FOAM_DEPTH-abs(FOAM_DEPTH - depth_diff * FOAM_WIDTH)) * (1/FOAM_DEPTH);
	#endif
	gl_FragColor = vec4(color + spec_color, 1);
	//gl_FragColor = vec4(depth_diff, 0, 0, 1);
}

