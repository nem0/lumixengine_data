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


#endif