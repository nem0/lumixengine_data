$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_texture, 15);
SAMPLER2D(u_avgLuminance, 14);

uniform vec4 u_bloomCutoff;

void main()
{
	float avg_loglum = max(0.1, exp(texture2D(u_avgLuminance, vec2(0.5, 0.5)).r));
	vec4 color = texture2D(u_texture, v_texcoord0);
	if(luma(color).r > avg_loglum * u_bloomCutoff.x) gl_FragColor = color;
	else gl_FragColor = vec4(0, 0, 0, 0);
}

