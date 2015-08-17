$input a_position, a_texcoord0, a_color
$output v_texcoord0, v_common

#include "common.sh"

void main()
{
	mat4 model = u_model[0];

	model = transpose(model);
	
    vec4 wpos = mul(model, vec4(a_position, 1.0));
	v_common = a_color.rgb;
	v_texcoord0 = a_texcoord0;

	gl_Position =  mul(u_viewProj, wpos);
}
