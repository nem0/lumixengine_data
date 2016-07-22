$input a_position 
$output v_wpos

#include "common.sh"

void main()
{
	mat4 model = u_model[0]; 

	vec3 wpos = mul(model, vec4(a_position, 1.0) ).xyz;
	v_wpos = wpos;
	
	gl_Position = mul(u_viewProj, vec4(v_wpos, 1.0) );	
}
