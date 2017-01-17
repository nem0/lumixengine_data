$input v_wpos, v_texcoord0

#include "common.sh"

uniform vec4 u_lightDirFov; 
uniform vec4 u_fogParams;
uniform vec4 u_fogColorDensity; 
SAMPLERCUBE(u_texColor, 0);


vec3 get_world_normal(vec2 frag_coord)
{
	float z = 1;
	vec4 posProj = vec4(frag_coord * 2 - 1, z, 1.0);
	vec4 wpos = mul(u_camInvViewProj, posProj);
	wpos /= wpos.w;
	vec3 view = mul(u_camInvView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - wpos.xyz;

	return -normalize(view);
}


float getFogFactorSky(vec3 camera_wpos, float fog_density, vec3 eye_dir, vec4 fog_params) 
{
	if(eye_dir.y == 0) return 1.0;
	float camera_height = camera_wpos.y;
	float to_top = max(0, (fog_params.x + fog_params.y) - camera_height);

	float avg_y = (fog_params.x + fog_params.y + camera_height) * 0.5;
	float avg_density = fog_density * clamp(1 - (avg_y - fog_params.x) / fog_params.y, 0, 1);
	float res = exp(-pow(avg_density * to_top / eye_dir.y, 2));
	res =  1 - clamp(res - (1-min(0.2, eye_dir.y)*5), 0, 1);
	return res;
}

void main()
{
	vec3 eye_dir = get_world_normal(v_wpos.xy);
	vec3 camera_wpos = mul(u_camInvView, vec4(0, 0, 0, 1)).xyz;
	float fog_factor = getFogFactorSky(camera_wpos, u_fogColorDensity.w, eye_dir, u_fogParams);
	vec4 sky_color = textureCube(u_texColor, eye_dir);
	gl_FragColor.xyz = mix(sky_color.rgb, u_fogColorDensity.rgb, fog_factor);
	gl_FragColor.w = 1;
}