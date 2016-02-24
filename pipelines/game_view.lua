local common = require "pipelines/common"

local ctx = { pipeline = this }

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

addFramebuffer(this, "blur_rgba8", {
	width = 2048,
	height = 2048,
	renderbuffers = {
		{ format = "rgba8" }
	}
})


pipeline_parameters.SSAO = false
pipeline_parameters.SSAO_blur = false
pipeline_parameters.sky_enabled = true

 
texture_uniform = createUniform(this, "u_texture")
blur_material = loadMaterial(this, "shaders/blur.mat")
screen_space_material = loadMaterial(this, "shaders/screen_space.mat")
ssao_material = loadMaterial(this, "shaders/ssao.mat")
sky_material = loadMaterial(this, "shaders/sky.mat")
common.initHDR(ctx)
common.initShadowmap(ctx)

function initScene()
	ctx.hdr_exposure_param = addRenderParamFloat(this, "HDR exposure", 1.0)
	ctx.dof_focal_distance_param = addRenderParamFloat(this, "DOF focal distance", 10.0)
	ctx.dof_focal_range_param = addRenderParamFloat(this, "DOF focal range", 10.0)
end

function renderSSAODPostprocess(this)
	if pipeline_parameters.SSAO then
		newView(this, "ssao_postprocess")
			setPass(this, "SCREEN_SPACE")
			enableBlending(this, "multiply")
			disableDepthWrite(this)
			setFramebuffer(this, "hdr")
			bindFramebufferTexture(this, "SSAO", 0, texture_uniform)
			drawQuad(this, -1.0, -1.0, 2, 2, screen_space_material);
	end
end


function SSAO(this)
	if pipeline_parameters.SSAO then
		newView(this, "ssao")
			setPass(this, "SSAO")
			disableBlending(this)
			disableDepthWrite(this)
			setFramebuffer(this, "SSAO")
			bindFramebufferTexture(this, "hdr", 1, texture_uniform)
			drawQuad(this, -1, -1, 2, 2, ssao_material);		

		if pipeline_parameters.SSAO_blur then
			newView(this, "ssao_blur_h")
				setPass(this, "BLUR_H")
				setFramebuffer(this, "blur_rgba8")
				disableDepthWrite(this)
				bindFramebufferTexture(this, "SSAO", 0, ctx.shadowmap_uniform)
				drawQuad(this, -1, -1, 2, 2, blur_material)
				enableDepthWrite(this)
			
			newView(this, "ssao_blur_h")
				setPass(this, "BLUR_V")
				setFramebuffer(this, "SSAO")
				disableDepthWrite(this)
				bindFramebufferTexture(this, "blur_rgba8", 0, ctx.shadowmap_uniform)
				drawQuad(this, -1, -1, 2, 2, blur_material);
				enableDepthWrite(this)		
		end
	end
end



function main(this)
	if pipeline_parameters.sky_enabled then
		newView(this, "sky")
			setPass(this, "SKY")
			setFramebuffer(this, "hdr")
			setActiveGlobalLightUniforms(this)
			disableDepthWrite(this)
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
			drawQuad(this, -1, -1, 2, 2, sky_material)
	end

	main_view = newView(this, "main")
		setPass(this, "MAIN")
		enableDepthWrite(this)
		if not pipeline_parameters.sky_enabled then
			clear(this, CLEAR_COLOR | CLEAR_DEPTH, 0xffffFFFF)
		end
		enableRGBWrite(this)
		setFramebuffer(this, "hdr")
		applyCamera(this, "main")
		setActiveGlobalLightUniforms(this)
		renderModels(this, {main_view})
end


function pointLight(this)
	newView(this, "point_light")
		setPass(this, "POINT_LIGHT")
		setFramebuffer(this, "hdr")
		disableDepthWrite(this)
		enableBlending(this, "add")
		applyCamera(this, "main")
		renderPointLightLitGeometry(this, 1, true)
end


function editor(this)
	if pipeline_parameters.render_gizmos then
		newView(this, "editor")			
			setPass(this, "EDITOR")
			setFramebuffer(this, "default")
			disableDepthWrite(this)
			disableBlending(this)
			applyCamera(this, "main")
			renderIcons(this)

		newView(this, "gizmo")
			setPass(this, "EDITOR")
			setFramebuffer(this, "default")
			applyCamera(this, "main")
			renderGizmos(this)
	end
end

 
function render(this)
	common.shadowmap(ctx, "main")
	main(this)
	common.particles(ctx, "main")
	pointLight(this)		
	SSAO(this)
	renderSSAODPostprocess(this)

	common.hdr(ctx, "main")
end

