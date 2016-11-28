$input v_wpos, v_texcoord0 // in...

#include "common.sh"


#define M_PI 3.14159265

SAMPLER2D(u_gbuffer0, 15);
SAMPLER2D(u_gbuffer1, 14);
SAMPLER2D(u_gbuffer2, 13);
SAMPLER2D(u_gbuffer_depth, 12);
SAMPLER2D(u_texShadowmap, 11);

uniform vec4 u_lightPosRadius;
uniform vec4 u_lightRgbAttenuation;
uniform vec4 u_ambientColor;
uniform vec4 u_lightDirFov; 
uniform mat4 u_shadowmapMatrices[4];
uniform vec4 u_fogColorDensity; 
uniform vec4 u_lightSpecular;
uniform vec4 u_fogParams;

void PBR_ComputeDirectLight(vec3 normal, vec3 lightDir, vec3 viewDir,
                            vec3 lightColor, float fZero, float roughness, float ndotv,
                            out vec3 outDiffuse, out vec3 outSpecular){
    // Compute halfway vector.
    vec3 halfVec = normalize(lightDir + viewDir);

    // Compute ndotl, ndoth,  vdoth terms which are needed later.
    float ndotl = max( dot(normal,   lightDir), 0.0);
    float ndoth = max( dot(normal,   halfVec),  0.0);       
    float hdotv = max( dot(viewDir,  halfVec),  0.0);

    // Compute diffuse using energy-conserving Lambert.
    // Alternatively, use Oren-Nayar for really rough 
    // materials or if you have lots of processing power ...
    outDiffuse = vec3_splat(ndotl) * lightColor;

    //cook-torrence, microfacet BRDF : http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
   
    float alpha = roughness * roughness;

    //D, GGX normaal Distribution function     
    float alpha2 = alpha * alpha;
    float sum  = ((ndoth * ndoth) * (alpha2 - 1.0) + 1.0);
    float denom = M_PI * sum * sum;
    float D = alpha2 / denom;  

    // Compute Fresnel function via Schlick's approximation.
    float fresnel = fZero + ( 1.0 - fZero ) * pow( 2.0, (-5.55473 * hdotv - 6.98316) * hdotv);
    
    //G Shchlick GGX Gometry shadowing term,  k = alpha/2
    float k = alpha * 0.5;

 /*   
    //classic Schlick ggx
    float G_V = ndotv / (ndotv * (1.0 - k) + k);
    float G_L = ndotl / (ndotl * (1.0 - k) + k);
    float G = ( G_V * G_L );
    
    float specular =(D* fresnel * G) /(4 * ndotv);
   */
 
    // UE4 way to optimise shlick GGX Gometry shadowing term
    //http://graphicrants.blogspot.co.uk/2013/08/specular-brdf-reference.html
    float G_V = ndotv + sqrt( (ndotv - ndotv * k) * ndotv + k );
    float G_L = ndotl + sqrt( (ndotl - ndotl * k) * ndotl + k );    
    // the max here is to avoid division by 0 that may cause some small glitches.
    float G = 1.0/max( G_V * G_L ,0.01); 

    float specular = D * fresnel * G * ndotl; 
 
    outSpecular = vec3_splat(specular) * lightColor;
}


void main()
{
	float f0 = 2;
	
	vec4 gbuffer1_val = texture2D(u_gbuffer1, v_texcoord0);
	vec3 normal = normalize(gbuffer1_val.xyz * 2 - 1);
	vec4 albedo = texture2D(u_gbuffer0, v_texcoord0);
	float roughness = albedo.w;
	float metallic = gbuffer1_val.w;
	vec4 value2 = texture2D(u_gbuffer2, v_texcoord0) * 64.0;
	
	vec3 wpos = getViewPosition(u_gbuffer_depth, u_camInvViewProj, v_texcoord0);

	vec4 camera_wpos = mul(u_camInvView, vec4(0, 0, 0, 1));
	vec3 view = normalize(camera_wpos.xyz - wpos);
	
	vec4 mat_specular_shininess = vec4(value2.x, value2.x, value2.x, value2.y);	

	
	float specular = 0.5;
	float nonMetalSpec = 0.08 * specular;
	vec4 specularColor = (nonMetalSpec - nonMetalSpec * metallic) + albedo * metallic;
	vec4 diffuseColor = albedo - albedo * metallic;
	
	vec3 direct_diffuse;
	vec3 direct_specular;
	PBR_ComputeDirectLight(normal, -u_lightDirFov.xyz, view, u_lightRgbAttenuation.rgb, f0, roughness, dot(normal, view), direct_diffuse, direct_specular);
	
/*	vec3 diffuse = shadeDirectionalLight(u_lightDirFov.xyz
					, view
					, u_lightRgbAttenuation.rgb
					, u_lightSpecular.rgb
					, normal
					, mat_specular_shininess
					, vec3(1, 1, 1));*/
	gl_FragColor.rgb = direct_diffuse * diffuseColor.rgb + direct_specular * specularColor.rgb + u_ambientColor.rgb * albedo.rgb;
	/*				
	float ndotl = -dot(normal, u_lightDirFov.xyz);
	diffuse = diffuse * directionalLightShadow(u_texShadowmap, u_shadowmapMatrices, vec4(wpos, 1), ndotl); 

	vec3 ambient = u_ambientColor.rgb * color.rgb;
	float fog_factor = getFogFactor(camera_wpos.xyz / camera_wpos.w, u_fogColorDensity.w, wpos.xyz, u_fogParams);
	gl_FragColor.xyz = mix(diffuse + ambient, u_fogColorDensity.rgb, fog_factor);*/
	gl_FragColor.w = 1;
}