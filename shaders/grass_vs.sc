$input a_position, a_normal, a_tangent, a_texcoord0, i_data0, i_data1, i_data2, i_data3
$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0

#include "common.sh"


void main()
{
	mat4 model;
	model[0] = i_data0;
	model[1] = i_data1;
	model[2] = i_data2;
	model[3] = i_data3;

	model = transpose(model);
	
	v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - mul(model, vec4(a_position, 1.0) ).xyz;
	float scale = clamp(1 - (length(v_view) - 10)/10, 0, 1);
    v_wpos = mul(model, vec4(a_position * scale, 1.0) ).xyz;
	#ifndef SHADOW
		vec4 normal = a_normal * 2.0 - 1.0;
		vec4 tangent = a_tangent * 2.0 - 1.0;

		v_normal = mul(model, normalize(vec4(a_position.x, 2.0, a_position.z, 0.0))).xyz;
		v_tangent = mul(model, vec4(tangent.xyz, 0.0) ).xyz;
		v_bitangent = cross(v_normal, v_tangent);
		v_texcoord0 = a_texcoord0;
	#endif

	gl_Position =  mul(u_viewProj, vec4(v_wpos, 1.0) );
}
