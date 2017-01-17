$input a_position, a_normal, a_tangent, a_texcoord0, i_data0, i_data1, i_data2, i_data3
$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2

#include "common.sh"

void main()
{
	mat4 model;
	model[0] = i_data0;
	model[1] = i_data1;
	model[2] = i_data2;
	model[3] = i_data3;

	vec3 position = a_position;
	v_wpos = instMul(model, vec4(position, 1.0) ).xyz;
	
	vec3 normal = (a_normal * 2.0 - 1.0).xyz;
	vec3 tangent = (a_tangent * 2.0 - 1.0).xyz;

	v_normal = instMul(model, vec4(normal, 0.0) ).xyz;
	v_tangent = instMul(model, vec4(tangent, 0.0) ).xyz;
	v_bitangent = cross(v_tangent, v_normal);
	v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - v_wpos;

	v_texcoord0 = a_texcoord0;
	v_common2 = mul(u_viewProj, vec4(v_wpos, 1.0) ); 
	gl_Position =  v_common2;
}
