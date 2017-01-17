$input v_wpos, v_texcoord0 // in...

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

#ifdef BLUR_H	
	vec4 color = texture2D(u_texture, v_wpos.xy) * BLUR9_WEIGHT(0)
		+ texture2D(u_texture, v_wpos.xy + vec2(1/u_textureSize.x, 0)) * BLUR9_WEIGHT(1)
		+ texture2D(u_texture, v_wpos.xy + vec2(2/u_textureSize.x, 0)) * BLUR9_WEIGHT(2)
		+ texture2D(u_texture, v_wpos.xy + vec2(3/u_textureSize.x, 0)) * BLUR9_WEIGHT(3)
		+ texture2D(u_texture, v_wpos.xy + vec2(4/u_textureSize.x, 0)) * BLUR9_WEIGHT(4)
		+ texture2D(u_texture, v_wpos.xy + vec2(-1/u_textureSize.x, 0)) * BLUR9_WEIGHT(1)
		+ texture2D(u_texture, v_wpos.xy + vec2(-2/u_textureSize.x, 0)) * BLUR9_WEIGHT(2)
		+ texture2D(u_texture, v_wpos.xy + vec2(-3/u_textureSize.x, 0)) * BLUR9_WEIGHT(3)
		+ texture2D(u_texture, v_wpos.xy + vec2(-4/u_textureSize.x, 0)) * BLUR9_WEIGHT(4);
#else
	vec4 color = texture2D(u_texture, v_wpos.xy) * BLUR9_WEIGHT(0)
		+ texture2D(u_texture, v_wpos.xy + vec2(0, 1/u_textureSize.y)) * BLUR9_WEIGHT(1)
		+ texture2D(u_texture, v_wpos.xy + vec2(0, 2/u_textureSize.y)) * BLUR9_WEIGHT(2)
		+ texture2D(u_texture, v_wpos.xy + vec2(0, 3/u_textureSize.y)) * BLUR9_WEIGHT(3)
		+ texture2D(u_texture, v_wpos.xy + vec2(0, 4/u_textureSize.y)) * BLUR9_WEIGHT(4)
		+ texture2D(u_texture, v_wpos.xy + vec2(0, -1/u_textureSize.y)) * BLUR9_WEIGHT(1)
		+ texture2D(u_texture, v_wpos.xy + vec2(0, -2/u_textureSize.y)) * BLUR9_WEIGHT(2)
		+ texture2D(u_texture, v_wpos.xy + vec2(0, -3/u_textureSize.y)) * BLUR9_WEIGHT(3)
		+ texture2D(u_texture, v_wpos.xy + vec2(0, -4/u_textureSize.y)) * BLUR9_WEIGHT(4);
#endif
		
	gl_FragColor.rgb = color.rgb;
	gl_FragColor.w = 1.0;
}
