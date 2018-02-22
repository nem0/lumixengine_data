$input v_wpos, v_texcoord0 // in...

/*
Film Grain based on:
Martins Upitis (martinsh) devlog-martinsh.blogspot.com
2013
This work is licensed under a Creative Commons Attribution 3.0 Unported License.

Perlin noise shader by toneburst:
http://machinesdontcare.wordpress.com/2009/06/25/3d-perlin-noise-sphere-vertex-shader-sourcecode/
*/

#include "common.sh"

SAMPLER2D(u_texture, 15);
SAMPLER2D(u_colorGradingLUT, 14);


uniform vec4 exposure;
uniform vec4 focal_range;
uniform vec4 u_time;
uniform vec4 u_textureSize;
uniform vec4 u_grainAmount;
uniform vec4 u_grainSize;
uniform vec4 u_vignette;
uniform vec4 max_dof_blur;
uniform vec4 clear_range;
uniform vec4 dof_near_multiplier;

#define timer u_time.x * 0.01
#define grainamount u_grainAmount.x
#define grainsize u_grainSize.x


    
vec4 rnm(in vec2 tc) 
{
    float noise =  sin(dot(tc + vec2(timer,timer),vec2(12.9898,78.233))) * 43758.5453;

	float noiseR =  fract(noise)*2.0-1.0;
	float noiseG =  fract(noise*1.2154)*2.0-1.0; 
	float noiseB =  fract(noise*1.3453)*2.0-1.0;
	float noiseA =  fract(noise*1.3647)*2.0-1.0;
	
	return vec4(noiseR,noiseG,noiseB,noiseA);
}

float fade(float t) {
	return t*t*t*(t*(t*6.0-15.0)+10.0);
}

float pnoise3D(vec3 p)
{
	const float permTexUnit = 1.0 / 256.0;
	const float permTexUnitHalf = 0.5 / 256.0;

	vec3 pi = permTexUnit * floor(p) + permTexUnitHalf; // Integer part, scaled so +1 moves permTexUnit texel
	vec3 pf = fract(p);									// Fractional part for interpolation

	float perm00 = rnm(pi.xy).a;
	vec3 grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
	float n000 = dot(grad000, pf);
	vec3 grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));

	float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a;
	vec3 grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
	float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
	vec3 grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));

	float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a;
	vec3 grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
	float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
	vec3 grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));

	float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a;
	vec3 grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
	float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
	vec3 grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
	float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));

	vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));

	vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));

	float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));

	return n_xyz;
}

vec2 coordRot(vec2 tex_coord, float angle)
{
	float aspect = u_textureSize.x / u_textureSize.y;
	float s = sin(angle);
	float c = cos(angle);
	vec2 tc = tex_coord * 2.0 - 1.0;
	float rotX = (tc.x * aspect * c) - (tc.y * s);
	float rotY = (tc.y * c) + (tc.x * aspect * s);
	rotX = rotX / aspect;
	rotY = rotY;
	return vec2(rotX, rotY) * 0.5 + 0.5;
}

vec3 filmGrain(vec2 tex_coord, vec3 in_color) 
{
#ifdef FILM_GRAIN 
	const float lumamount = 0.1;
	vec2 rotCoordsR = coordRot(tex_coord, timer);
	vec3 noise = vec3_splat(pnoise3D(vec3(rotCoordsR * vec2(u_textureSize.xy / grainsize),0.0)));
	float luminance = mix(0.0, luma(in_color).x, lumamount);
	float lum = smoothstep(0.2, 0.0, luminance);
	lum += luminance;
	
	noise = mix(vec3_splat(0.0), vec3_splat(pow(lum, 4.0)), noise);
	return in_color + noise * grainamount;
#else
	return in_color;
#endif
}


vec3 vignette(vec2 tex_coord, vec3 in_color)
{
#ifdef VIGNETTE
	float dist = distance(tex_coord, vec2(0.5, 0.5));
	float vignette = smoothstep(u_vignette.x, u_vignette.x - u_vignette.y, dist);
	return mix(in_color, in_color * vignette, 0.5);
#else
	return in_color;
#endif
}


#ifdef COLOR_GRADING
// http://kpulv.com/359/Dev_Log__Color_Grading_Shader/
vec4 sampleColorGradingLUT(vec3 uv, float width) {
	float innerWidth = width - 1.0;
	float sliceSize = 1.0 / width; // space of 1 slice
	float slicePixelSize = sliceSize / width; // space of 1 pixel
	float sliceInnerSize = slicePixelSize * innerWidth; // space of width pixels
	float zSlice0 = min(floor(uv.z * innerWidth), innerWidth);
	float zSlice1 = min(zSlice0 + 1.0, innerWidth);
	float xOffset = slicePixelSize * 0.5 + uv.x * sliceInnerSize;
	float s0 = xOffset + (zSlice0 * sliceSize);
	float s1 = xOffset + (zSlice1 * sliceSize);
	float yPixelSize = sliceSize;
	float yOffset = yPixelSize * 0.5 + uv.y * (1.0 - yPixelSize);
	vec4 slice0Color = texture2D(u_colorGradingLUT,vec2(s0, yOffset));
	vec4 slice1Color = texture2D(u_colorGradingLUT, vec2(s1, yOffset));
	float zOffset = frac(uv.z * innerWidth);
	vec4 result = lerp(slice0Color, slice1Color, zOffset);
	return result;
}

#else


#endif

vec3 colorGrading(vec3 color)
{
	const float SIZE = 16;
	#ifdef COLOR_GRADING
		return sampleColorGradingLUT(color, 16);
	#else
		return color;
	#endif
}


void main()
{
	vec3 color = texture2D(u_texture, v_texcoord0).xyz;
	
	//color *= exposure.x;
	color = vignette(v_texcoord0, color);
	color = filmGrain(v_texcoord0, color);
	color = colorGrading(color);
	
	gl_FragColor = vec4(color, 1.0f);
}



