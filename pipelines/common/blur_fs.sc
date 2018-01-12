$input v_tc0, v_tc1, v_tc2

#include "common.sh"

uniform vec4 u_textureSize;
SAMPLER2D(u_texture, 15);

void main()
{
	vec4 color = texture2D(u_texture, v_tc0.xy) * 0.2270270270
		+ texture2D(u_texture, v_tc1.xy) * 0.3162162162
		+ texture2D(u_texture, v_tc1.zw) * 0.0702702703
		+ texture2D(u_texture, v_tc2.xy) * 0.3162162162
		+ texture2D(u_texture, v_tc2.zw) * 0.0702702703;
		
	gl_FragColor = color;
}
