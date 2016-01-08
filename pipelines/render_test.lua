framebuffers = {

	{
		name = "SSAO",
		width = 1024,
		height = 768,
		renderbuffers = {
			{format="rgba8"},
			{format = "depth24"}
		}
	},

	{
		name = "SSAO_blurred",
		width = 1024,
		height = 768,
		renderbuffers = {
			{format="rgba8"},
			{format = "depth24"}
		}
	},

	
	{
		name = "shadowmap",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format="r32f"},
			{format = "depth32"}
		}
	},
	
	{
		name = "point_light_shadowmap",
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth32"}
		}
	},

	{
		name = "point_light2_shadowmap",
		width = 1024,
		height = 1024,
		renderbuffers = {
			{format = "depth32"}
		}
	},

	{
		name = "blur",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format = "r32f"}
		}
	},
}


parameters = {
	particles_enabled = true,
	blur_shadowmap = true,
	render_shadowmap_debug = false,
	render_gizmos = true,
	SSAO = false,
	SSAO_debug = false,
	SSAO_blur = false
}

 
function init(pipeline)
	shadowmap_uniform = createUniform(pipeline, "u_texShadowmap")
	texture_uniform = createUniform(pipeline, "u_texture")
	blur_material = loadMaterial(pipeline, "pipelines/blur.mat")
	screen_space_material = loadMaterial(pipeline, "models/editor/screen_space.mat")
	ssao_material = loadMaterial(pipeline, "pipelines/ssao.mat")
end


function renderSSAODPostprocess(pipeline)
	if parameters.SSAO then
		setPass(pipeline, "SCREEN_SPACE")
		enableBlending(pipeline, "multiply")
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, "default")
		bindFramebufferTexture(pipeline, "SSAO", 0, texture_uniform)
		drawQuad(pipeline, -1.0, -1.0, 2, 2, screen_space_material);
	end
end


function SSAO(pipeline)
	if parameters.SSAO then
		setPass(pipeline, "SSAO")
		disableBlending(pipeline)
		disableDepthWrite(pipeline)
		setFramebuffer(pipeline, "SSAO")
		bindFramebufferTexture(pipeline, "default", 1, texture_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, ssao_material);		

		if parameters.SSAO_blur then
			setPass(pipeline, "BLUR_H")
				beginNewView(pipeline, "h");
				setFramebuffer(pipeline, "blur")
				disableDepthWrite(pipeline)
				bindFramebufferTexture(pipeline, "SSAO", 0, shadowmap_uniform)
				drawQuad(pipeline, -1, -1, 2, 2, blur_material)
				enableDepthWrite(pipeline)
			
			setPass(pipeline, "BLUR_V")
				beginNewView(pipeline, "v");
				setFramebuffer(pipeline, "SSAO")
				disableDepthWrite(pipeline)
				bindFramebufferTexture(pipeline, "blur", 0, shadowmap_uniform)
				drawQuad(pipeline, -1, -1, 2, 2, blur_material);
				enableDepthWrite(pipeline)		
		end
	end
end

 
function shadowmap(pipeline)
	setPass(pipeline, "SHADOW")         
	applyCamera(pipeline, "editor")
	--disableRGBWrite(pipeline)
	--disableAlphaWrite(pipeline)
	setFramebuffer(pipeline, "shadowmap")
	renderShadowmap(pipeline, 1, "editor") 

	renderLocalLightsShadowmaps(pipeline, 1, {"point_light_shadowmap", "point_light2_shadowmap"}, "editor")

	if parameters.blur_shadowmap then
		setPass(pipeline, "BLUR_H")
		setFramebuffer(pipeline, "blur")
		disableDepthWrite(pipeline)
		bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, blur_material)
		enableDepthWrite(pipeline)
		
		setPass(pipeline, "BLUR_V")
		setFramebuffer(pipeline, "shadowmap")
		disableDepthWrite(pipeline)
		bindFramebufferTexture(pipeline, "blur", 0, shadowmap_uniform)
		drawQuad(pipeline, -1, -1, 2, 2, blur_material);
		enableDepthWrite(pipeline)
	end
end


function main(pipeline)
	setPass(pipeline, "MAIN")
	clear(pipeline, "all", 0xffaaaaff)
	enableRGBWrite(pipeline)
	setFramebuffer(pipeline, "default")
	applyCamera(pipeline, "editor")
	renderModels(pipeline, 1, false)
--		executeCustomCommand(pipeline, "render_physics");
	renderDebugShapes(pipeline)
end


function particles(pipeline)
	if parameters.particles_enabled then
		setPass(pipeline, "PARTICLES")
		disableDepthWrite(pipeline)
		applyCamera(pipeline, "editor")
		renderParticles(pipeline)
	end	
end


function pointLight(pipeline)
	setPass(pipeline, "POINT_LIGHT")
	disableDepthWrite(pipeline)
	enableBlending(pipeline, "add")
	applyCamera(pipeline, "editor")
	renderModels(pipeline, 1, true)
end

 
function render(pipeline)
	shadowmap(pipeline)
	main(pipeline)
	particles(pipeline)
	pointLight(pipeline)		
	SSAO(pipeline)
	renderSSAODPostprocess(pipeline)
end

