framebuffers = {
	{
		name = "default",
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
 
function init(pipeline)
	shadowmap_uniform = createUniform(pipeline, "u_texShadowmap")
	texture_uniform = createUniform(pipeline, "u_texture")
	blur_material = loadMaterial(pipeline, "pipelines/blur.mat")
	sky_material = loadMaterial(pipeline, "models/sky/sky.mat")
	screen_space_material = loadMaterial(pipeline, "models/editor/screen_space.mat")
end


function renderShadowmapDebug(pipeline)
	setPass(pipeline, "SCREEN_SPACE")
		setFramebuffer(pipeline, "default")
		bindFramebufferTexture(pipeline, "shadowmap", 0, texture_uniform)
		drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5, screen_space_material);
		--drawQuad(pipeline, -1.0, -1.0, 2, 2, screen_space_material);
end

 
function render(pipeline)
	setPass(pipeline, "SHADOW")         
		--disableRGBWrite(pipeline)
		--disableAlphaWrite(pipeline)
		setFramebuffer(pipeline, "shadowmap")
		renderShadowmap(pipeline, 1, "editor") 

		renderLocalLightsShadowmaps(pipeline, 1, {"point_light_shadowmap", "point_light2_shadowmap"}, "editor")

	if true then
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
	
	setPass(pipeline, "MAIN")
		clear(pipeline, "all", 0xbbd3edff)
		enableRGBWrite(pipeline)
		setFramebuffer(pipeline, "default")
		applyCamera(pipeline, "editor")
		renderModels(pipeline, 1, false)
--		executeCustomCommand(pipeline, "render_physics");
		renderDebugShapes(pipeline)

	setPass(pipeline, "PARTICLES")
		disableDepthWrite(pipeline)
		applyCamera(pipeline, "editor")
		renderParticles(pipeline)
		
	--setPass(pipeline, "SKY")
		--disableBlending(pipeline)
		--drawQuad(pipeline, -1, -1, 2, 2, sky_material);

	setPass(pipeline, "POINT_LIGHT")
		disableDepthWrite(pipeline)
		enableBlending(pipeline)
		applyCamera(pipeline, "editor")
		renderModels(pipeline, 1, true)
		
	setPass(pipeline, "EDITOR")
		enableDepthWrite(pipeline)
		disableBlending(pipeline)
		clear(pipeline, "depth", 0)
		applyCamera(pipeline, "editor")
		executeCustomCommand(pipeline, "render_gizmos")
		executeCustomCommand(pipeline, "render_physics")
		--renderDebugTexts(pipeline)     

	--renderShadowmapDebug(pipeline)

	--print(80, 0, string.format("FPS: %.2f", getFPS(pipeline))	)
end
