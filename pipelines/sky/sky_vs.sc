$input a_position, a_color, a_texcoord0
$output v_wpos, v_texcoord0

#include "common.sh"


void main()
{
	vec3 wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
	v_wpos = wpos;
	v_texcoord0 = a_texcoord0;
	
	gl_Position = mul(u_viewProj, vec4(wpos, 1.0) );	
}