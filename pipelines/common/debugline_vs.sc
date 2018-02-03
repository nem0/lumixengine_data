$input a_position, a_color0
$output v_color

#include "common.sh"

void main()
{
	v_color = a_color0;
	vec3 wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
	gl_Position = mul(u_viewProj, vec4(wpos, 1.0) );
}
