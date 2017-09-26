$input v_tc0, v_tc1, v_tc2, v_tc3, v_tc4

#include "common.sh"

uniform vec4 u_textureSize;
SAMPLER2D(u_texture, 15);

void main()
{
	#define _BLUR9_WEIGHT_0 1.0
	#define _BLUR9_WEIGHT_1 0.9
	#define _BLUR9_WEIGHT_2 0.55
	#define _BLUR9_WEIGHT_3 0.18
	#define _BLUR9_WEIGHT_4 0.1
	#define _BLUR9_NORMALIZE (_BLUR9_WEIGHT_0+2.0*(_BLUR9_WEIGHT_1+_BLUR9_WEIGHT_2+_BLUR9_WEIGHT_3+_BLUR9_WEIGHT_4) )
	#define BLUR9_WEIGHT(_x) (_BLUR9_WEIGHT_##_x/_BLUR9_NORMALIZE)

	vec4 color = texture2D(u_texture, v_tc0.xy) * 0.2270270270
		+ texture2D(u_texture, v_tc1.xy) * 0.3162162162
		+ texture2D(u_texture, v_tc1.zw) * 0.0702702703
		+ texture2D(u_texture, v_tc2.xy) * 0.3162162162
		+ texture2D(u_texture, v_tc2.zw) * 0.0702702703;
		
	gl_FragColor = color;
}
