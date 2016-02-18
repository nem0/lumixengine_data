$input a_position, a_normal, a_tangent, a_texcoord0, a_weight, a_indices
$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2

#include "common.sh"

uniform mat4 u_boneMatrices[128];
uniform vec4 u_layer;

void main()
{
	mat4 model = 
		mul(a_weight.x * u_boneMatrices[int(a_indices.x)] + 
		a_weight.y * u_boneMatrices[int(a_indices.y)] +
		a_weight.z * u_boneMatrices[int(a_indices.z)] +
		a_weight.w * u_boneMatrices[int(a_indices.w)], u_model[0]);

	#ifdef FUR
		a_position += a_normal * (u_layer.x * 0.03);
	#endif

    v_wpos = mul(model, vec4(a_position, 1.0)).xyz;
	#ifndef SHADOW
		vec4 normal = a_normal * 2.0 - 1.0;
		vec4 tangent = a_tangent * 2.0 - 1.0;

		v_normal = mul(model, vec4(normal.xyz, 0.0) ).xyz;
		v_tangent = mul(model, vec4(tangent.xyz, 0.0) ).xyz;
		v_bitangent = cross(v_normal, v_tangent);
		v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - v_wpos;
	#endif

	
	v_texcoord0 = a_texcoord0;
	v_common2 = mul(u_viewProj, vec4(v_wpos, 1.0) ); 
	gl_Position =  v_common2;
}
