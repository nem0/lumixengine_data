$input v_wpos, v_texcoord0 // in...

#include "common.sh"

uniform vec4 u_textureSize;
SAMPLER2D(u_texture, 15);

void main()
{
	vec4 offset = vec4(1 / u_textureSize.x, 0, 1 / u_textureSize.x, 1 / u_textureSize.x);
	gl_FragColor = (texture2D(u_texture, v_wpos.xy)
		 + texture2D(u_texture, v_wpos.xy + offset.xy) // 1 0
		 + texture2D(u_texture, v_wpos.xy + offset.yz) // 0 1
		 + texture2D(u_texture, v_wpos.xy + offset.zw)) // 1 1 
		 * 0.25;
}
