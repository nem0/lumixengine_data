$input a_position, a_normal, a_tangent, a_texcoord0, a_weight, a_indices
$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2

#include "common.sh"

uniform mat4 u_boneMatrices[128];

void main()
{
	vec4 normal = a_normal * 2.0 - 1.0;
	vec4 tangent = a_tangent * 2.0 - 1.0;

	v_texcoord0 = a_texcoord0;
	v_view = mul(u_view, vec4(0.0, 0.0, 1.0, 0.0)).xyz;

	mat4 mtx = a_weight.x * u_boneMatrices[int(a_indices.x)] + 
	a_weight.y *  u_boneMatrices[int(a_indices.y)] +
	a_weight.z *  u_boneMatrices[int(a_indices.z)] +
	a_weight.w * u_boneMatrices[int(a_indices.w)];

  	vec4 pos = mul(mtx, vec4(a_position, 1.0));

  	v_normal = mul(mtx, normal);
	v_normal = mul(u_model[0], v_normal);

  	v_tangent = mul(mtx, tangent);
	v_tangent = mul(u_model[0], v_tangent);

    v_bitangent = cross(v_normal, v_tangent) * (a_tangent.w * 2.0 - 1.0);
	
	v_wpos = pos.xyz;
	v_common2 = mul(u_modelViewProj, vec4(v_wpos, 1.0) );
	gl_Position = v_common2;
}
