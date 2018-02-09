$input v_texcoord0 // in...

#include "common.sh"

#ifndef FIXED_EXPOSURE
	SAMPLER2D(u_avgLuminance, 14);
#endif
SAMPLER2D(u_texture, 15);

uniform vec4 midgray;
uniform vec4 u_exposure;


// Unchared2 tone mapping (See http://filmicgames.com)
float Uncharted2Tonemap(float x)
{
	const float A = 0.15;
	const float B = 0.50;
	const float C = 0.10;
	const float D = 0.20;
	const float E = 0.02;
	const float F = 0.30;
	return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

vec3 tonemap(vec3 in_color)
{
	#ifdef FIXED_EXPOSURE
		float avg_loglum = 0.3;
	#else
		float avg_loglum = exp(texture2D(u_avgLuminance, vec2(0.5, 0.5)).r);
	#endif
	float lum = luma(in_color).x;
	float map_middle = (midgray.r / (avg_loglum + 0.001)) * lum;
	float ld = Uncharted2Tonemap(map_middle) / Uncharted2Tonemap(11.0);
	return (in_color / max(0.00001, lum)) * ld;
}

void main()
{
	vec4 color = texture2D(u_texture, v_texcoord0);

	gl_FragColor.rgba = vec4(toGamma(u_exposure.x * tonemap(color.rgb)), 1.0f);
}
