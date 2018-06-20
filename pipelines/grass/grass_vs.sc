$input a_position, a_normal, a_tangent, a_texcoord0, i_data0, i_data1, i_data2
$output v_normal, v_common, v_texcoord0

#include "common.sh"

uniform vec4 u_time;
uniform vec4 u_grassMaxDist;

SAMPLER2D(u_texNoise, 1);

void main()
{
	const float space_frequency = 0.3;
	const float frequency = 1;
	const float move_factor = 0.06;
	const vec3 wind_dir = vec3(0.707, 0, 0.707);

	v_common = vec3_splat(a_position.y);
 	v_texcoord0 = a_texcoord0;
	
	v_normal.xyz = i_data2.xyz;
	
	float max_dist = u_grassMaxDist.x;
	float scale_dist = 10;
	vec3 view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - i_data0.xyz;
	float scale = clamp(1 - (length(view) - (max_dist - scale_dist))/scale_dist, 0, 1) * i_data0.w;
	
	vec3 wpos = i_data0.xyz + mul_quat_vec3(i_data1, scale * a_position);
	if(a_position.y>=0.1)
	{
		float len = length(a_position);
		wpos += move_factor * (sin(frequency * u_time.x + dot(wpos, wind_dir) * space_frequency - a_position.y*2) + 0.5) * wind_dir;
	}
	gl_Position = mul(u_viewProj, vec4(wpos, 1.0));
}

