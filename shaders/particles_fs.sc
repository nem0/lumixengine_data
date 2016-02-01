$input v_wpos, v_texcoord0, v_common // in...

#include "common.sh"

SAMPLER2D(u_texColor, 0);

void main()
{
	gl_FragColor.rgba = texture2D(u_texColor, v_texcoord0) * v_common.x;
}
