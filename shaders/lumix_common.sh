#ifndef __LUMIX_COMMON_SH__
#define __LUMIX_COMMON_SH__


vec4 lit(float _ndotl, float _rdotv, float shininess)
{
	float diff = max(0.0, _ndotl);
	
	float _exp = shininess;
	float spec = step(0.0, _ndotl) * pow(max(0.0, _rdotv), _exp);
	return vec4(1.0, diff, step(1.0, shininess) * spec, 1.0);
}


vec2 blinn(vec3 _lightDir, vec3 _normal, vec3 _viewDir)
{
	float ndotl = dot(_normal, _lightDir);
	vec3 reflected = _lightDir - 2.0 * ndotl * _normal;
	float rdotv = max(0.0, dot(-reflected, _viewDir));
	return vec2(ndotl, rdotv);
}


float getFogFactor(float fog_coord, float fog_density) 
{ 
	float fResult = exp(-pow(fog_density * fog_coord, 2.0)); 
	fResult = 1.0-clamp(fResult, 0.0, 1.0); 
	return fResult;
}


vec3 calcGlobalLight(vec3 light_dir, vec3 _light_color, vec3 _normal)
{
	return max(0.0, dot(-light_dir, _normal)) * _light_color;	
}


float hardShadow(sampler2D _sampler, vec4 _shadowCoord, float _bias)
{
	vec2 texCoord = _shadowCoord.xy/_shadowCoord.w;

	bool outside = any(greaterThan(texCoord, vec2_splat(1.0)))
				|| any(lessThan   (texCoord, vec2_splat(0.0)))
				 ;

	if (outside)
	{
		return 1.0;
	}

	float receiver = (_shadowCoord.z-_bias)/_shadowCoord.w;
	float occluder = //unpackRgbaToFloat(texture2D(_sampler, texCoord) );
		texture2D(_sampler, texCoord).x * 0.5 + 0.5;
	float visibility = step(receiver, occluder);
	return visibility;
}


float PCF(sampler2D _sampler, vec4 _shadowCoord, float _bias, vec4 _pcfParams, vec2 _texelSize)
{
	float result = 0.0;
	vec2 offset = _pcfParams.zw * _texelSize * _shadowCoord.w;

	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(-1.5, -1.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(-1.5, -0.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(-1.5,  0.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(-1.5,  1.5) * offset, 0.0, 0.0), _bias);

	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(-0.5, -1.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(-0.5, -0.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(-0.5,  0.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(-0.5,  1.5) * offset, 0.0, 0.0), _bias);

	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(0.5, -1.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(0.5, -0.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(0.5,  0.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(0.5,  1.5) * offset, 0.0, 0.0), _bias);

	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(1.5, -1.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(1.5, -0.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(1.5,  0.5) * offset, 0.0, 0.0), _bias);
	result += hardShadow(_sampler, _shadowCoord + vec4(vec2(1.5,  1.5) * offset, 0.0, 0.0), _bias);

	return result / 16.0;
}


float ESM(sampler2D _sampler, vec4 _shadowCoord, float _bias, float _depthMultiplier)
{
	vec2 texCoord = _shadowCoord.xy/_shadowCoord.w;

	bool outside = any(greaterThan(texCoord, vec2_splat(1.0)))
				|| any(lessThan   (texCoord, vec2_splat(0.0)))
				 ;

	if (outside)
	{
		return 1.0;
	}

	float receiver = (_shadowCoord.z-_bias)/_shadowCoord.w;
	float occluder = (texture2D(_sampler, texCoord).r * 0.5 + 0.5);

	float visibility = clamp(exp(_depthMultiplier * (occluder-receiver) ), 0.0, 1.0);

	return visibility;
}


float VSM(sampler2D _sampler, vec4 _shadowCoord, float _bias, float _depthMultiplier, float _minVariance)
{
	vec2 texCoord = _shadowCoord.xy/_shadowCoord.w;

	bool outside = any(greaterThan(texCoord, vec2_splat(1.0)))
				|| any(lessThan   (texCoord, vec2_splat(0.0)))
				 ;

	if (outside)
	{
		return 1.0;
	}

	float receiver = (_shadowCoord.z*0.5+0.5-_bias)/_shadowCoord.w * _depthMultiplier;
	vec4 rgba = texture2D(_sampler, texCoord);
	vec2 occluder = vec2(unpackHalfFloat(rgba.rg), unpackHalfFloat(rgba.ba)) * _depthMultiplier;
	
	if (receiver < occluder.x)
	{
		return 1.0;
	}
	
	//return 0;
	float variance = max(occluder.y - (occluder.x*occluder.x), _minVariance);
	float d = receiver - occluder.x;

	float visibility = variance / (variance + d*d);

	return visibility;
}


float smoothShadow(sampler2D shadowmap, vec2 uv, float compare)
{
	return smoothstep(compare-0.00001, compare, texture2D(shadowmap, uv).x * 0.5 + 0.5);
}


float pointLightShadow(sampler2D shadowmap, mat4 shadowmapMatrices[4], vec4 position, float fov)
{
	const float DEPTH_MULTIPLIER = 900;

	if(fov > 3.14159)
	{
		vec4 a = mul(shadowmapMatrices[0], position);
		vec4 b = mul(shadowmapMatrices[1], position);
		vec4 c = mul(shadowmapMatrices[2], position);
		vec4 d = mul(shadowmapMatrices[3], position);
		
		a = a / a.w;
		b = b / b.w;
		c = c / c.w;
		d = d / d.w;

	
		bool selection0 = all(lessThan(a.xy, vec2_splat(0.99))) && all(greaterThan(a.xy, vec2_splat(0.01))) && a.z < 1;
		bool selection1 = all(lessThan(b.xy, vec2_splat(0.99))) && all(greaterThan(b.xy, vec2_splat(0.01))) && b.z < 1;
		bool selection2 = all(lessThan(c.xy, vec2_splat(0.99))) && all(greaterThan(c.xy, vec2_splat(0.01))) && c.z < 1;
		bool selection3 = all(lessThan(d.xy, vec2_splat(0.99))) && all(greaterThan(d.xy, vec2_splat(0.01))) && d.z < 1;
		
		
		if(selection0)
			return ESM(shadowmap, vec4(vec2(a.x*0.5, a.y*0.5), a.z, 1.0), 0.0, DEPTH_MULTIPLIER);
		else if(selection1)
			return ESM(shadowmap, vec4(vec2(0.5+b.x*0.5, b.y*0.5), b.z, 1.0), 0.0, DEPTH_MULTIPLIER);
		else if(selection2)
			return ESM(shadowmap, vec4(vec2(c.x*0.5, 0.5+c.y*0.5), c.z, 1.0), 0.0, DEPTH_MULTIPLIER);
		else 
			return ESM(shadowmap, vec4(vec2(0.5+d.x*0.5, 0.5+d.y*0.5), d.z, 1.0), 0.0, DEPTH_MULTIPLIER);
	}
	else
	{
		vec4 tmp = mul(shadowmapMatrices[0], position);
		vec3 shadow_coord = tmp.xyz / tmp.w;
			return ESM(shadowmap, vec4(shadow_coord.xy, shadow_coord.z, 1.0), 0.0, DEPTH_MULTIPLIER);
	}
}


float directionalLightShadow(sampler2D shadowmap, mat4 shadowmapMatrices[4], vec4 position)
{
	vec3 shadow_coord[4];
	shadow_coord[0] = mul(shadowmapMatrices[0], position).xyz;
	shadow_coord[1] = mul(shadowmapMatrices[1], position).xyz;
	shadow_coord[2] = mul(shadowmapMatrices[2], position).xyz;
	shadow_coord[3] = mul(shadowmapMatrices[3], position).xyz;

	vec2 tt[4];
	tt[0] = vec2(shadow_coord[0].x * 0.5, shadow_coord[0].y * 0.5);
	tt[1] = vec2(0.5 + shadow_coord[1].x * 0.5, shadow_coord[1].y * 0.5);
	tt[2] = vec2(shadow_coord[2].x * 0.5, 0.5 + shadow_coord[2].y * 0.5);
	tt[3] = vec2(0.5 + shadow_coord[3].x * 0.5, 0.5 + shadow_coord[3].y * 0.5);

	float bias = 0.0;
	int split_index = 3;
	if(step(shadow_coord[0].x, 0.99) * step(shadow_coord[0].y, 0.99)
		* step(0.01, shadow_coord[0].x)	* step(0.01, shadow_coord[0].y) > 0.0)
	{
		split_index = 0;
	}
	else if(step(shadow_coord[1].x, 0.99) * step(shadow_coord[1].y, 0.99)
		* step(0.01, shadow_coord[1].x)	* step(0.01, shadow_coord[1].y) > 0.0)
	{
		split_index = 1;
	}
	else if(step(shadow_coord[2].x, 0.99) * step(shadow_coord[2].y, 0.99)
		* step(0.01, shadow_coord[2].x)	* step(0.01, shadow_coord[2].y) > 0.0)
	{
		split_index = 2;
	}
	else if(step(shadow_coord[3].x, 0.99) * step(shadow_coord[3].y, 0.99)
		* step(0.01, shadow_coord[3].x)	* step(0.01, shadow_coord[3].y) > 0.0)
	{
		split_index = 3;
	}
	else
		return 1.0;

	return  
		//VSM(shadowmap, vec4(tt[split_index].xy, shadow_coord[split_index].z, 1.0), 0.001, 450, 0.0002);
		ESM(shadowmap, vec4(tt[split_index].xy, shadow_coord[split_index].z, 1.0), 0.0, 90000);
		//hardShadow(shadowmap, vec4(tt[split_index].xy, shadow_coord[split_index].z, 1.0), bias);
		//PCF(shadowmap, vec4(tt[split_index].xy, shadow_coord[split_index].z, 1.0), bias, vec4(1, 1, 1, 1), vec2(1/1024.0,1/1024.0));
		//step(shadow_coord[split_index].z, 1) * smoothShadow(shadowmap, tt[split_index], shadow_coord[split_index].z);
}

#endif