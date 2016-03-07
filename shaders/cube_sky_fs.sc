$input v_wpos, v_texcoord0

#include "common.sh"

uniform vec4 u_lightDirFov; 
uniform mat4 u_camView;
uniform mat4 u_camInvView;
uniform mat4 u_camInvViewProj;
uniform mat4 u_camInvProj;
SAMPLERCUBE(u_texColor, 0);


vec3 get_world_normal(vec2 frag_coord)
{
	float z = 1;
	vec4 posProj = vec4(frag_coord * 2 - 1, z, 1.0);
	vec4 wpos = mul(u_camInvViewProj, posProj);
	wpos /= wpos.w;
	vec3 view = mul(u_camInvView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - wpos;

    return -normalize(view);
}


vec3 getEyeDir(vec2 uv)
{
	uv = uv * 2 - 1;
	
	mat3 m;
	m[0] = vec3(1, 0, 0);
	m[1] = vec3(0, 1, 0);
	m[2] = vec3(0, 0, 1);
	
	vec3 v = mul(m, normalize(vec3(-uv.x, -uv.y, 1)));
	
	return v; 
}


void main()
{
	vec3 eye_dir = get_world_normal(v_texcoord0);
	gl_FragColor = textureCube(u_texColor, eye_dir);
	
	//vec4(1, 0, 0, 1);
	/*vec3 lightdir = -u_lightDirFov.xyz;
	vec3 eyedir = get_world_normal(v_texcoord0);
	
	float alpha = dot(eyedir, lightdir);
	
	gl_FragColor = vec4(eyedir, 1);
	//return ;
	float rayleigh_factor = phase(alpha, -0.01)*u_brightness.x;
	float mie_factor = phase(alpha, mie_distribution)*u_brightness.y;
	float spot = smoothstep(0.0, u_sunSize, phase(alpha, 0.9995))*u_brightness.z;
	
	vec3 eye_position = vec3(0.0, surface_height, 0.0);
	float eye_depth = atmospheric_depth(eye_position, eyedir);
	float step_length = eye_depth/float(step_count);
	
	float eye_extinction = horizon_extinction(
		eye_position, eyedir, surface_height-0.15
	);
	
	vec3 rayleigh_collected = vec3(0.0, 0.0, 0.0);
	vec3 mie_collected = vec3(0.0, 0.0, 0.0);
	
	for(int i=0; i<step_count; i++)
	{
		float sample_distance = step_length*float(i);
		vec3 position = eye_position + eyedir*sample_distance;
		float extinction = horizon_extinction(position, lightdir, surface_height-0.35);
		float sample_depth = atmospheric_depth(position, lightdir);
		vec3 influx = absorb(sample_depth, vec3_splat(intensity), u_strength.x)*extinction;
		rayleigh_collected += absorb(sample_distance, u_airColor.rgb*influx, u_strength.y);
		mie_collected += absorb(sample_distance, influx, u_strength.z);
	}
	
	rayleigh_collected = (rayleigh_collected * eye_extinction * pow(eye_depth, rayleigh_collection_power))/float(step_count);
	mie_collected = (mie_collected * eye_extinction * pow(eye_depth, mie_collection_power))/float(step_count);
	
	vec3 color = vec3(spot*mie_collected + mie_factor*mie_collected +rayleigh_factor*rayleigh_collected);
	
	gl_FragColor.xyz = color;
	gl_FragColor.w = 1;*/
}