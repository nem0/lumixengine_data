framebuffers = {
	{
		name = "shadowmap",
		width = 2048,
		height = 2048,
		renderbuffers = {
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
	}

}
 
function init(pipeline)
	shadowmap_uniform = createUniform(pipeline, "u_texShadowmap")
	shadowmap2_uniform = createUniform(pipeline, "u_texShadowmap2")
end
 
function renderShadowmapDebug(pipeline)
	setPass(pipeline, "SCREEN_SPACE")
		bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)
		bindFramebufferTexture(pipeline, "point_light_shadowmap", 0, shadowmap2_uniform)
		drawQuad(pipeline, 0.5, 0.98, 0.48, -0.48)
end
 
function render(pipeline)

	setPass(pipeline, "SHADOW")         
		disableRGBWrite(pipeline)
		disableAlphaWrite(pipeline)
		setFramebuffer(pipeline, "shadowmap")
		renderShadowmap(pipeline, 1, "editor") 

		renderLocalLightsShadowmaps(pipeline, 1, {"point_light_shadowmap", "point_light2_shadowmap"}, "editor")
		
	setPass(pipeline, "MAIN")
		enableRGBWrite(pipeline)
		bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)
		setFramebuffer(pipeline, "default")
		clear(pipeline, "all")
		applyCamera(pipeline, "editor")
		renderModels(pipeline, 1, false)
--		executeCustomCommand(pipeline, "render_physics");
		renderDebugShapes(pipeline)

	setPass(pipeline, "POINT_LIGHT")
		disableDepthWrite(pipeline)
		enableBlending(pipeline)
		applyCamera(pipeline, "editor")
		renderModels(pipeline, 1, true)

	setPass(pipeline, "EDITOR")
		enableDepthWrite(pipeline)
		disableBlending(pipeline)
		clear(pipeline, "depth")
		applyCamera(pipeline, "editor")
		executeCustomCommand(pipeline, "render_gizmos")
		executeCustomCommand(pipeline, "render_physics")
		--renderDebugTexts(pipeline)     
	renderShadowmapDebug(pipeline)
	
	print(0, 0, string.format("FPS: %.2f", getFPS(pipeline))	)
end
