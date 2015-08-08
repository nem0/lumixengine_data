$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0

/*
 * Copyright 2011-2015 Branimir Karadzic. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include "common.sh"

SAMPLER2D(u_texColor, 0);
SAMPLER2D(u_texNormal, 1);
SAMPLER2D(u_shadowmap, 2);
#ifdef SPECULAR_TEXTURE
	SAMPLER2D(u_texSpecular, 3);
#endif
uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbInnerR;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_lightSpecular;
uniform vec4 u_materialSpecularShininess;

float getFogFactor(float fFogCoord) 
{ 
	float fResult = exp(-pow(u_fogColorDensity.w * fFogCoord, 2.0)); 
	fResult = 1.0-clamp(fResult, 0.0, 1.0); 
	return fResult;
}

vec2 blinn(vec3 _lightDir, vec3 _normal, vec3 _viewDir)
{
	float ndotl = dot(_normal, _lightDir);
	vec3 reflected = _lightDir - 2.0 * ndotl * _normal; // reflect(_lightDir, _normal);
	float rdotv = max(0.0, dot(-reflected, _viewDir));
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
	
	float _exp = u_materialSpecularShininess.w;
	float spec = step(0.0, _ndotl) * pow(max(0.0, _rdotv), _exp);
	return vec4(1.0, diff, step(1.0, u_materialSpecularShininess.w) * spec, 1.0);
}

vec4 powRgba(vec4 _rgba, float _pow)
{
	vec4 result;
	result.xyz = pow(_rgba.xyz, vec3_splat(_pow) );
	result.w = _rgba.w;
	return result;
}

vec3 calcLight(mat3 _tbn, vec3 _wpos, vec3 _normal, vec3 _view, vec2 uv)
{
	vec3 lp = u_lightPosRadius.xyz - _wpos;
	float attn = 1.0 - smoothstep(u_lightRgbInnerR.w, 1.0, length(lp) / u_lightPosRadius.w);
	vec3 lightDir = normalize(lp);
	vec2 bln = blinn(lightDir, _normal, _view);
	vec4 lc = lit(bln.x, bln.y, 1.0);
	vec3 rgb = u_lightRgbInnerR.xyz * saturate(lc.y) * attn;
	
	rgb = rgb + u_lightSpecular.xyz * u_materialSpecularShininess.xyz *
	#ifdef SPECULAR_TEXTURE
		texture2D(u_texSpecular, uv).rgb * 
	#endif
		saturate(lc.z);
	return rgb;
}

vec3 calcGlobalLight(vec3 _light_color, vec3 _normal)
{
	return max(0.0, dot(u_lightDirFov.xyz, -_normal)) * _light_color;	
}

float VSM(sampler2D depths, vec2 uv, float compare)
{
	return smoothstep(compare-0.0001, compare, texture2D(depths, uv).x);
}

float getShadowmapValue(vec4 position)
{
	vec3 shadow_coord[4];
	shadow_coord[0] = mul(u_shadowmapMatrices[0], position).xyz;
	shadow_coord[1] = mul(u_shadowmapMatrices[1], position).xyz;
	shadow_coord[2] = mul(u_shadowmapMatrices[2], position).xyz;
	shadow_coord[3] = mul(u_shadowmapMatrices[3], position).xyz;

	vec2 tt[4];
	tt[0] = vec2(shadow_coord[0].x * 0.5, 0.50 + shadow_coord[0].y * 0.5);
	tt[1] = vec2(0.5 + shadow_coord[1].x * 0.5, 0.50 + shadow_coord[1].y * 0.5);
	tt[2] = vec2(shadow_coord[2].x * 0.5, shadow_coord[2].y * 0.5);
	tt[3] = vec2(0.5 + shadow_coord[3].x * 0.5, shadow_coord[3].y * 0.5);

	int split_index = 3;
	if(step(shadow_coord[0].x, 0.99) * step(shadow_coord[0].y, 0.99)
		* step(0.01, shadow_coord[0].x)	* step(0.01, shadow_coord[0].y) > 0.0)
		split_index = 0;
	else if(step(shadow_coord[1].x, 0.99) * step(shadow_coord[1].y, 0.99)
		* step(0.01, shadow_coord[1].x)	* step(0.01, shadow_coord[1].y) > 0.0)
		split_index = 1;
	else if(step(shadow_coord[2].x, 0.99) * step(shadow_coord[2].y, 0.99)
		* step(0.01, shadow_coord[2].x)	* step(0.01, shadow_coord[2].y) > 0.0)
		split_index = 2;
	  
	return step(shadow_coord[split_index].z, 1) * VSM(u_shadowmap, tt[split_index], shadow_coord[split_index].z);
}         

void main()
{     
	#ifdef POINT_LIGHT
		gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	#endif 

	#ifdef SHADOW
		vec4 color = texture2D(u_texColor, v_texcoord0);
		if(color.a < 0.3)
			discard;
		gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	#else
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
		vec3 view = normalize(v_view);

		vec4 color = /*toLinear*/(texture2D(u_texColor, v_texcoord0) );
		if(color.a < 0.3)
			discard;
					 
		vec3 diffuse;
		#ifdef POINT_LIGHT
			diffuse = calcLight(tbn, v_wpos, mul(tbn, normal), view, v_texcoord0);
			diffuse = diffuse.xyz * color.rgb;
		#else
			diffuse = calcGlobalLight(u_lightRgbInnerR.rgb, mul(tbn, normal));
			diffuse = diffuse.xyz * color.rgb;
			diffuse = diffuse * getShadowmapValue(vec4(v_wpos, 1.0)); 
		#endif

		#ifdef MAIN
			vec3 ambient = u_ambientColor.rgb * color.rgb;
		#else
			vec3 ambient = vec3(0, 0, 0);
		#endif  

		vec4 view_pos = mul(u_view, vec4(v_wpos, 1.0));
		float fog_factor = getFogFactor(view_pos.z / view_pos.w);
		gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);
		#ifdef POINT_LIGHT
			//gl_FragColor.rgb = vec3(xxx, 0.0, 0.0);
		#endif
		gl_FragColor.w = 1.0;
		//gl_FragColor = toGamma(gl_FragColor);
	#endif                  
}
