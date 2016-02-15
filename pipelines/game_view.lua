require "pipelines/common"

addFramebuffer(this, "default", {
	width = 1024,
	height = 768,
	renderbuffers = {
		{format="rgba8"},
	}
})

addFramebuffer(this, "hdr", {
	width = 1024,
	height = 1024,
	screen_size = true;
	renderbuffers = {
		{ format = "rgba16f" },
		{ format = "depth32" }
	}
})

addFramebuffer(this, "SSAO", {
	width = 512,
	height = 512,
	renderbuffers = {
		{format="rgba8"},
		{format = "depth24"}
	}
})

addFramebuffer(this, "SSAO_blurred", {
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
		{format = "r32f"}
	}
})


parameters.SSAO = false
parameters.SSAO_blur = false
parameters.sky_enabled = true

 
texture_uniform = createUniform(this, "u_texture")
blur_material = loadMaterial(this, "shaders/blur.mat")
screen_space_material = loadMaterial(this, "shaders/screen_space.mat")
ssao_material = loadMaterial(this, "shaders/ssao.mat")
sky_material = loadMaterial(this, "shaders/sky.mat")
initHDR(this)
initShadowmap(this)

function initScene()
	hdr_exposure_param = addRenderParamFloat(this, "HDR exposure", 1.0)
end

function renderSSAODPostprocess(this)
	if parameters.SSAO then
		setPass(this, "SCREEN_SPACE")
		enableBlending(this, "multiply")
		disableDepthWrite(this)
		setFramebuffer(this, "hdr")
		bindFramebufferTexture(this, "SSAO", 0, texture_uniform)
		drawQuad(this, -1.0, -1.0, 2, 2, screen_space_material);
	end
end


function SSAO(this)
	if parameters.SSAO then
		setPass(this, "SSAO")
		disableBlending(this)
		disableDepthWrite(this)
		setFramebuffer(this, "SSAO")
		bindFramebufferTexture(this, "hdr", 1, texture_uniform)
		drawQuad(this, -1, -1, 2, 2, ssao_material);		

		if parameters.SSAO_blur then
			setPass(this, "BLUR_H")
				beginNewView(this, "h");
				setFramebuffer(this, "blur")
				disableDepthWrite(this)
				bindFramebufferTexture(this, "SSAO", 0, shadowmap_uniform)
				drawQuad(this, -1, -1, 2, 2, blur_material)
				enableDepthWrite(this)
			
			setPass(this, "BLUR_V")
				beginNewView(this, "v");
				setFramebuffer(this, "SSAO")
				disableDepthWrite(this)
				bindFramebufferTexture(this, "blur", 0, shadowmap_uniform)
				drawQuad(this, -1, -1, 2, 2, blur_material);
				enableDepthWrite(this)		
		end
	end
end



function main(this)
	if parameters.sky_enabled then
		setPass(this, "SKY")
			setFramebuffer(this, "hdr")
			setActiveGlobalLightUniforms(this)
			disableDepthWrite(this)
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
			drawQuad(this, -1, -1, 2, 2, sky_material)
	end

	setPass(this, "MAIN")
		enableDepthWrite(this)
		if not parameters.sky_enabled then
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
		end
		enableRGBWrite(this)
		setFramebuffer(this, "hdr")
		applyCamera(this, "main")
		setActiveGlobalLightUniforms(this)
		renderModels(this)
end


function pointLight(this)
	setPass(this, "POINT_LIGHT")
		setFramebuffer(this, "hdr")
		disableDepthWrite(this)
		enableBlending(this, "add")
		applyCamera(this, "main")
		renderPointLightLitGeometry(this, 1, true)
end


function editor(this)
	if parameters.render_gizmos then
		setPass(this, "EDITOR")
			setFramebuffer(this, "default")
			disableDepthWrite(this)
			disableBlending(this)
			applyCamera(this, "main")
			renderIcons(this)

		beginNewView(this, "gizmo")
			setFramebuffer(this, "default")
			applyCamera(this, "main")
			renderGizmos(this)
	end
end

 
function render(this)
	shadowmap("main")
	main(this)
	particles("main")
	pointLight(this)		
	SSAO(this)
	renderSSAODPostprocess(this)

	hdr("main")
end

