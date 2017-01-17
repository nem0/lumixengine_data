$input v_wpos

#include "common.sh"

SAMPLER2D(u_texColor, 0);
SAMPLER2D(u_gbuffer_depth, 15);

uniform mat4 u_decalMatrix;


void main()
{
	vec3 screen_coord = getScreenCoord(v_wpos);
	vec3 wpos = getViewPosition(u_gbuffer_depth, u_invViewProj, screen_coord.xy * 0.5 + 0.5);
	
	vec3 tmp = mul(u_decalMatrix, vec4(wpos, 1)).xyz;
	
	if(any(greaterThan(abs(tmp), vec3_splat(1.0)))) discard;
	
	vec4 color = texture2D(u_texColor, tmp.xy * 0.5 + 0.5);
	if(color.a < 0.5) discard;
	gl_FragColor = color;
}
