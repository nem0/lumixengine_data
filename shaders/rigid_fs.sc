$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0 // in...

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "common.sh"

SAMPLER2D(u_texColor, 0);
SAMPLER2D(u_texNormal, 1);
SAMPLER2D(u_shadowmap, 2);
uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbInnerR;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 


vec2 blinn(vec3 _lightDir, vec3 _normal, vec3 _viewDir)
{
	float ndotl = dot(_normal, _lightDir);
	vec3 reflected = _lightDir - 2.0*ndotl*_normal; // reflect(_lightDir, _normal);
	float rdotv = dot(reflected, _viewDir);
	return vec2(ndotl, rdotv);
}

float fresnel(float _ndotl, float _bias, float _pow)
{
	float facing = (1.0 - _ndotl);
	return max(_bias + (1.0 - _bias) * pow(facing, _pow), 0.0);
}

vec4 lit(float _ndotl, float _rdotv, float _m)
{
	float diff = max(0.0, _ndotl);
	float spec = step(0.0, _ndotl) * max(0.0, _rdotv * _m);
	return vec4(1.0, diff, spec, 1.0);
}

vec4 powRgba(vec4 _rgba, float _pow)
{
	vec4 result;
	result.xyz = pow(_rgba.xyz, vec3_splat(_pow) );
	result.w = _rgba.w;
	return result;
}

vec3 calcLight(mat3 _tbn, vec3 _wpos, vec3 _normal, vec3 _view)
{
	vec3 lp = u_lightPosRadius.xyz - _wpos;
	float attn = 1.0 - smoothstep(u_lightRgbInnerR.w, 1.0, length(lp) / u_lightPosRadius.w);
	vec3 lightDir = normalize(lp);
	vec2 bln = blinn(lightDir, _normal, _view);
	vec4 lc = lit(bln.x, bln.y, 1.0);
	vec3 rgb = u_lightRgbInnerR.xyz * saturate(lc.y) * attn;
	return rgb;
}

vec3 calcGlobalLight(vec3 _light_color, vec3 _normal)
{
	return max(0.0, dot(u_lightDirFov.xyz, _normal)) * _light_color;	
}

void main()
{
	mat3 tbn = mat3(
				normalize(v_tangent),
				normalize(v_bitangent),
				normalize(v_normal)
				);

	vec3 normal;
	#ifdef NORMAL_MAPPING
		normal.xy = texture2D(u_texNormal, v_texcoord0).xy * 2.0 - 1.0;
		normal.z = sqrt(1.0 - dot(normal.xy, normal.xy) );
	#else
		normal = vec3(0.0, 0.0, 1.0);
	#endif
	vec3 view = -normalize(v_view);

	vec4 color = toLinear(texture2D(u_texColor, v_texcoord0) );
				 
	vec3 diffuse;
	#ifdef POINT_LIGHT
		diffuse = calcLight(tbn, v_wpos, mul(tbn, normal), view);
	#else
		diffuse = calcGlobalLight(u_lightRgbInnerR.rgb, mul(tbn, normal));
	#endif
	diffuse = diffuse.xyz * color.rgb;

	#ifdef MAIN
		vec3 ambient = u_ambientColor.rgb * color.rgb;
	#else
		vec3 ambient = vec3(0, 0, 0);
	#endif  

	gl_FragColor.xyz = ambient + diffuse; //max(vec3_splat(0.05), lightColor.xyz)*color.xyz;
	gl_FragColor.w = 1.0;
//	gl_FragColor = toGamma(gl_FragColor);
//	gl_FragColor = vec4(mul(tbn, normal), 1.0);
}
