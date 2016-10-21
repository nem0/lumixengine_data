$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 15);

void main()
{
	vec4 color = texture2D(u_texture, v_texcoord0);
	if(luma(color).r > 0.5) gl_FragColor = color;
	else gl_FragColor = vec4(0, 0, 0, 0);
}

