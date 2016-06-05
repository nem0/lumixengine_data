$input v_wpos, v_view, v_normal, v_tangent, v_bitangent, v_texcoord0, v_common2

#include "common.sh"

#ifndef SHADOW
	SAMPLER2D(u_texShadowmap, 15);
#endif

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity;
uniform vec4 u_lightSpecular;
uniform vec4 u_materialColorShininess;
uniform vec4 u_attenuationParams;
uniform vec4 u_fogParams;

void main() {
	vec4 color = vec4(0.176662, 0.414470, 0.798995, 1.000000);
	#ifdef DEFERRED
		gl_FragData[0] = vec4(color.rgb, 1);
		gl_FragData[1].xyz = v_normal;
		gl_FragData[1].w = 1;
		gl_FragData[2] = vec4(1,1,1,1);
	#else					
		vec3 wnormal;
		wnormal = normalize(v_normal.xyz);

		vec3 view = normalize(v_view);
					 
		vec3 texture_specular = vec3(1, 1, 1);

		vec3 diffuse;
		#ifdef POINT_LIGHT
			diffuse = shadePointLight(u_lightDirFov
				, v_wpos
				, wnormal
				, view
				, v_texcoord0
				, u_lightPosRadius
				, u_lightRgbAttenuation
				, u_materialColorShininess
				, u_lightSpecular.rgb
				, texture_specular
				);
			diffuse = diffuse.xyz * color.rgb;
		#else
			diffuse = shadeDirectionalLight(u_lightDirFov.xyz
				, view
				, u_lightRgbAttenuation.rgb
				, u_lightSpecular.rgb
				, wnormal
				, u_materialColorShininess
				, texture_specular);
			diffuse = diffuse.xyz * color.rgb; 
		#endif
  
		vec3 ambient = vec3(.6, .6, .6) * color.rgb;

		gl_FragColor.xyz = diffuse + ambient;
		gl_FragColor.w = 1.0;	
	#endif
}
