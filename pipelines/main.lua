require "pipelines/common"

parameters.SSAO = false
parameters.SSAO_debug = false
parameters.SSAO_blur = false
parameters.sky_enabled = true

addFramebuffer(this, "default", {
	width = 1024,
	height = 1024,
	renderbuffers = {
		{ format = "rgba8" },
	}
})

addFramebuffer(this,  "SSAO", {
	width = 512,
	height = 512,
	renderbuffers = {
		{format="rgba8"},
		{format = "depth24"}
	}
})

addFramebuffer(this,  "SSAO_blurred", {
	width = 512,
	height = 512,
	renderbuffers = {
		{format="rgba8"},
		{format = "depth24"}
	}
})

addFramebuffer(this, "blur", {
	width = 2048,
	height = 2048,
	renderbuffers = {
		{ format = "r32f" }
	}
})
  
initHDR(this)
initShadowmap(this)

texture_uniform = createUniform(this, "u_texture")
blur_material = loadMaterial(this, "shaders/blur.mat")
screen_space_material = loadMaterial(this, "shaders/screen_space.mat")
ssao_material = loadMaterial(this, "shaders/ssao.mat")
sky_material = loadMaterial(this, "shaders/sky.mat")

function initScene()
	hdr_exposure_param = addRenderParamFloat(this, "HDR exposure", 1.0)
	dof_focal_distance_param = addRenderParamFloat(this, "DOF focal distance", 10.0)
	dof_focal_range_param = addRenderParamFloat(this, "DOF focal range", 10.0)
end

function renderSSAODDebug()
	if parameters.SSAO_debug then
		newView(this, "ssao_debug")
			setPass(this, "SCREEN_SPACE")
			newView(this, "SHADOWMAP_DEBUG")
			disableBlending(this)
			disableDepthWrite(this)
			setFramebuffer(this, "default")
			bindFramebufferTexture(this, "SSAO", 0, texture_uniform)
			drawQuad(this, 0.48, 0.48, 0.5, 0.5, screen_space_material)
	end
end


function renderSSAODPostprocess()
	if parameters.SSAO then
		newView(this, "ssao_postprocess")
			setPass(this, "SCREEN_SPACE")
			enableBlending(this, "multiply")
			disableDepthWrite(this)
			setFramebuffer(this, "hdr")
			bindFramebufferTexture(this, "SSAO", 0, texture_uniform)
			drawQuad(this, -1.0, -1.0, 2, 2, screen_space_material)
	end
end


function SSAO()
	if parameters.SSAO then
		newView(this, "ssao")
			setPass(this, "SSAO")
			disableBlending(this)
			disableDepthWrite(this)
			setFramebuffer(this, "SSAO")
			bindFramebufferTexture(this, "hdr", 1, texture_uniform)
			drawQuad(this, -1, -1, 2, 2, ssao_material)

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
				drawQuad(this, -1, -1, 2, 2, blur_material)
				enableDepthWrite(this)		
		end
	end
end

function main()
	if parameters.sky_enabled then
		newView(this, "sky")
			setPass(this, "SKY")
			setFramebuffer(this, "hdr")
			disableDepthWrite(this)
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
			setActiveGlobalLightUniforms(this, sky_material)
			drawQuad(this, -1, -1, 2, 2, sky_material)
	end

	main_view = newView(this, "MAIN")
		setPass(this, "MAIN")
		enableDepthWrite(this)
		if not parameters.sky_enabled then
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
		end
		enableRGBWrite(this)
		setFramebuffer(this, "hdr")
		applyCamera(this, "editor")
		setActiveGlobalLightUniforms(this)
		renderDebugShapes(this)
end


function fur()
	fur_view = newView(this, "FUR")
		setPass(this, "FUR")
		setFramebuffer(this, "hdr")
		disableDepthWrite(this)
		enableBlending(this, "alpha")
		applyCamera(this, "editor")
		setActiveGlobalLightUniforms(this)
		renderModels(this, {main_view, fur_view})
end


function pointLight()
	newView(this, "POINT_LIGHT")
		setPass(this, "POINT_LIGHT")
		setFramebuffer(this, "hdr")
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
	fur(this)
	SSAO(this)
	renderSSAODPostprocess(this)
	
	hdr("editor")
	editor(this)
	renderSSAODDebug(this)
	shadowmapDebug(this)
end

