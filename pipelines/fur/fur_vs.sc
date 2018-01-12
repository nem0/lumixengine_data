#ifdef SKINNED
	$input a_position, a_normal, a_tangent, a_texcoord0, a_weight, a_indices
#else
	$input a_position, a_normal, a_tangent, a_texcoord0
#endif
	
$output v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2

#include "common.sh"

uniform mat4 u_boneMatrices[128];
uniform vec4 u_layer;
uniform vec4 u_furLength;
uniform vec4 u_gravity;

void main()
{
	vec4 normal = a_normal * 2.0 - 1.0;
	vec4 tangent = a_tangent * 2.0 - 1.0;
	#ifdef SKINNED
		mat4 model = 
			mul(u_model[0], a_weight.x * u_boneMatrices[int(a_indices.x)] + 
			a_weight.y * u_boneMatrices[int(a_indices.y)] +
			a_weight.z * u_boneMatrices[int(a_indices.z)] +
			a_weight.w * u_boneMatrices[int(a_indices.w)]);
	#else
		mat4 model = u_model[0];
	#endif	
	

    v_wpos = mul(model, vec4(a_position, 1.0)).xyz;
	#ifndef SHADOW
		v_normal = mul(model, vec4(normal.xyz, 0.0) ).xyz;
		v_tangent = mul(model, vec4(tangent.xyz, 0.0) ).xyz;
		v_bitangent = cross(v_normal, v_tangent);
		v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - v_wpos;
		#ifdef FUR
			v_wpos += (vec3(0, u_gravity.x * u_layer.x, 0) + v_normal.xyz) * u_layer.x * u_furLength.x * 0.001;
		#endif
	#endif

	
	v_texcoord0 = a_texcoord0;
	v_common2 = mul(u_viewProj, vec4(v_wpos, 1.0) ); 
	gl_Position =  v_common2;
}
