$input a_position
$output v_wpos, v_texcoord0, v_view

#include "common.sh"

void main()
{
	vec3 wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
	v_wpos = wpos;
	v_texcoord0 = a_position.xy;
	
	v_view = mul(u_invView, vec4(0.0, 0.0, 0.0, 1.0)).xyz - v_wpos;
	gl_Position = mul(u_viewProj, vec4(v_wpos, 1.0) );	
}
