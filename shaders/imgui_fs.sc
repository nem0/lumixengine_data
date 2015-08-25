$input v_texcoord0, v_common2

#include <bgfx_shader.sh>

SAMPLER2D(s_texColor, 0);

void main()
{
	float alpha = texture2D(s_texColor, v_texcoord0).w;
	gl_FragColor = vec4(v_common2.xyz, alpha * v_common2.w);
}
