$input a_position, i_data0, i_data1, i_data2, i_data3, i_data4, i_data5, i_data6, i_data7
$output v_wpos, v_texcoord0, v_view, v_pos_radius, v_color_attn, v_dir_fov, v_specular 

#include "common.sh"

void main()
{
	mat4 model;
	model[0] = i_data0;
	model[1] = i_data1;
	model[2] = i_data2;
	model[3] = i_data3;

	v_pos_radius = i_data4;
	v_color_attn = i_data5;
	v_dir_fov = i_data6;
	v_specular = i_data7;
	
	vec3 wpos = instMul(model, vec4(a_position, 1.0) ).xyz;
	v_wpos = wpos;
	v_texcoord0 = a_position.xy;
	
	v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - v_wpos;
	gl_Position = mul(u_viewProj, vec4(v_wpos, 1.0) );	
}
