$input a_position, a_normal, a_tangent, a_texcoord0, i_data0, i_data1, i_data2, i_data3, i_data4
$output v_wpos, v_normal, v_common, v_texcoord0, v_view

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

	v_common = vec3(a_position.y, a_position.y, a_position.y);
 	v_texcoord0 = a_texcoord0;
	
	mat4 model;
	model[0] = i_data0;
	model[1] = i_data1;
	model[2] = i_data2;
	model[3] = i_data3;
	
	v_normal.xyz = i_data4.xyz;
	
	float max_dist = u_grassMaxDist.x;
	float scale_dist = 10;
	vec3 view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - instMul(model, vec4(a_position, 1.0) ).xyz;
	float scale = clamp(1 - (length(view) - (max_dist - scale_dist))/scale_dist, 0, 1);
	
	vec3 wpos = instMul(model, vec4(scale * a_position, 1.0) ).xyz;
	if(a_position.y>=0.1)
	{
		float len = length(a_position);
		wpos += move_factor * (sin(frequency * u_time.x + dot(wpos, wind_dir) * space_frequency - a_position.y*2) + 0.5) * wind_dir;
	}
	v_wpos = wpos;
	v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - v_wpos;
	gl_Position = mul(u_viewProj, vec4(v_wpos, 1.0));
}

