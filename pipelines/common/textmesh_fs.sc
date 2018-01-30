$input v_texcoord0, v_common2

#include "common.sh"

SAMPLER2D(s_texColor, 0);

void main()
{
	vec4 t = texture2D(s_texColor, v_texcoord0);
	gl_FragColor = vec4(v_common2.xyz * t.rgb, t.w * v_common2.w);
}
