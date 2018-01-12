$input a_position, a_color, a_texcoord0
$output v_tc0, v_tc1, v_tc2

#include "common.sh"

uniform vec4 u_textureSize;

void main()
{
	vec3 wpos = mul(u_model[0], vec4(a_position, 1.0) ).xyz;
	
	v_tc0 = vec4(a_texcoord0.xy, 0, 0);
	#ifdef BLUR_H
		v_tc1 = vec4(
			a_texcoord0.x + 1.3846153846 * u_textureSize.z, a_texcoord0.y, 
			a_texcoord0.x + 3.2307692308 * u_textureSize.z, a_texcoord0.y
		);
		v_tc2 = vec4(
			a_texcoord0.x - 1.3846153846 * u_textureSize.z, a_texcoord0.y, 
			a_texcoord0.x - 3.2307692308 * u_textureSize.z, a_texcoord0.y
		);
	#else
		v_tc1 = vec4(
			a_texcoord0.x, a_texcoord0.y + 1.3846153846 * u_textureSize.w,
			a_texcoord0.x, a_texcoord0.y + 3.2307692308 * u_textureSize.w
		);
		v_tc2 = vec4(
			a_texcoord0.x, a_texcoord0.y - 1.3846153846 * u_textureSize.w, 
			a_texcoord0.x, a_texcoord0.y - 3.2307692308 * u_textureSize.w
		);
	#endif
	
	gl_Position = mul(u_viewProj, vec4(wpos, 1.0) );	
}
