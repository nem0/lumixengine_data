$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texShadowmap, 0);

void main()
{
	vec4 color = texture2D(u_texShadowmap, v_texcoord0);

	gl_FragColor.r = color.r;
	gl_FragColor.w = 1.0;
}
