$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 15);

void main()
{
	vec4 color = texture2D(u_texture, v_texcoord0);

	gl_FragColor.rgba = vec4(toGamma(color.rgb), 1.0f);
}
