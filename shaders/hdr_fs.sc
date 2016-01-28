$input v_wpos, v_texcoord0 // in...

#include "common.sh"

SAMPLER2D(u_hdrBuffer, 0);

uniform vec4 exposure;

void main()
{
	v_texcoord0.y = -v_texcoord0.y;
    const float gamma = 2.2;
    vec3 hdrColor = texture2D(u_hdrBuffer, v_texcoord0).rgb;
  
    vec3 mapped = vec3_splat(1.0) - exp(-hdrColor * exposure.x);
    mapped = pow(mapped, vec3_splat(1.0 / gamma));
	gl_FragColor = vec4(mapped, 1.0);
}
