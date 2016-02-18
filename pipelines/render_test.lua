require "pipelines/common"

addFramebuffer(this, "SSAO", {
	width = 1024,
	height = 768,
	renderbuffers = {
		{format="rgba8"},
		{format = "depth24"}
	}
})

addFramebuffer(this, "SSAO_blurred", {
	width = 1024,
	height = 768,
	renderbuffers = {
		{format="rgba8"},
		{format = "depth24"}
	}
})


addFramebuffer(this, "blur", {
	width = 2048,
	height = 2048,
	renderbuffers = {
		{format = "r32f"}
	}
})

parameters.render_gizmos = true
parameters.SSAO = false
parameters.SSAO_debug = false
parameters.SSAO_blur = false
 
shadowmap_uniform = createUniform(this, "u_texShadowmap")
texture_uniform = createUniform(this, "u_texture")
blur_material = loadMaterial(this, "shaders/blur.mat")
screen_space_material = loadMaterial(this, "shaders/screen_space.mat")
ssao_material = loadMaterial(this, "shaders/ssao.mat")
initShadowmap()


function renderSSAODPostprocess()
	if parameters.SSAO then
		newView(this, "ssao_postprocess")
			setPass(this, "SCREEN_SPACE")
			enableBlending(this, "multiply")
			disableDepthWrite(this)
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "SSAO", 0, texture_uniform)
			drawQuad(this, -1.0, -1.0, 2, 2, screen_space_material);
	end
end


function SSAO()
	if parameters.SSAO then
		newView(this, "ssao")
			setPass(this, "SSAO")
			disableBlending(this)
			disableDepthWrite(this)
			setFramebuffer(this, "SSAO")
			bindFramebufferTexture(this, "default", 1, texture_uniform)
			drawQuad(this, -1, -1, 2, 2, ssao_material);		

		if parameters.SSAO_blur then
			newView(this, "ssao_blur_h")
				setPass(this, "BLUR_H")
				setFramebuffer(this, "blur")
				disableDepthWrite(this)
				bindFramebufferTexture(this, "SSAO", 0, shadowmap_uniform)
				drawQuad(this, -1, -1, 2, 2, blur_material)
				enableDepthWrite(this)
			
			newView(this, "ssao_blur_v")
				setPass(this, "BLUR_V")
				setFramebuffer(this, "SSAO")
				disableDepthWrite(this)
				bindFramebufferTexture(this, "blur", 0, shadowmap_uniform)
				drawQuad(this, -1, -1, 2, 2, blur_material);
				enableDepthWrite(this)		
		end
	end
end
 

function main()
	main_view = newView(this, "main")
		setPass(this, "MAIN")
		clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffaaaaff)
		enableRGBWrite(this)
		setFramebuffer(this, "default")
		applyCamera(this, "editor")
		setActiveGlobalLightUniforms(this)
		renderModels(this, {main_view})
		renderDebugShapes(this)
end


function pointLight()
	newView(this, "point_light")
		setPass(this, "POINT_LIGHT")
		disableDepthWrite(this)
		enableBlending(this, "add")
		applyCamera(this, "editor")
		renderPointLightLitGeometry(this)
end

 
function render()
	shadowmap("editor")
	main(this)
	particles("editor")
	pointLight(this)		
	SSAO(this)
	renderSSAODPostprocess(this)
end

