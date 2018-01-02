$input v_texcoord0

#include "common.sh"


SAMPLER2D(s_texColor, 15);
#ifdef FINAL
	SAMPLER2D(s_texPrevLum, 14);
#endif
uniform vec4 u_offset[4];


void main()
{
	vec3 rgb0 = texture2D(s_texColor, v_texcoord0 + u_offset[0].xy).rgb;
	vec3 rgb1 = texture2D(s_texColor, v_texcoord0 + u_offset[1].xy).rgb;
	vec3 rgb2 = texture2D(s_texColor, v_texcoord0 + u_offset[2].xy).rgb;
	vec3 rgb3 = texture2D(s_texColor, v_texcoord0 + u_offset[3].xy).rgb;
	#ifdef HDR_EXTRACT_LUMINANCE
		float avg = log(0.05 + luma(rgb0).r)
				  + log(0.05 + luma(rgb1).r)
				  + log(0.05 + luma(rgb2).r)
				  + log(0.05 + luma(rgb3).r)
				  ;
		avg *= 1.0/4.0;

		gl_FragColor.r = avg;
	#else
		float avg = (rgb0 + rgb1 + rgb2 + rgb3) / 4.0;
		#ifdef FINAL
			float prev_lum = texture2D(s_texPrevLum, vec2(0.5, 0.5)).r;
			float result = mix(avg, prev_lum, 0.95);
			if (isnan(result)) result = 0;
			gl_FragColor.r = result;
		#else
			gl_FragColor.r = avg;
		#endif
	#endif
}
