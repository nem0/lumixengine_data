framebuffers = {
	{
		name = "shadowmap",
		width = 2048,
		height = 2048,
		renderbuffers = {
			{format = "depth32"}
		}
	}
}
 
function init(pipeline)
	shadowmap_uniform = createUniform(pipeline, "u_texShadowmap")
end
 
function renderShadowmapDebug(pipeline)
	setPass(pipeline, "SCREEN_SPACE")
		bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)
		drawQuad(pipeline, 0.48, 0.48, 0.5, 0.5)
end
 
function render(pipeline)

	setPass(pipeline, "SHADOW")         
		setFramebuffer(pipeline, "shadowmap")
		renderShadowmap(pipeline, 1, "editor") 
		bindFramebufferTexture(pipeline, "shadowmap", 0, shadowmap_uniform)
		
	setPass(pipeline, "MAIN")
		setFramebuffer(pipeline, "default")
		clear(pipeline, "all")
		applyCamera(pipeline, "editor")
		renderModels(pipeline, 1, false)
--		executeCustomCommand(pipeline, "render_physics");
		renderDebugLines(pipeline)

	setPass(pipeline, "POINT_LIGHT")
		enableBlending(pipeline)
		applyCamera(pipeline, "editor")
		renderModels(pipeline, 1, true)
		disableBlending(pipeline)
	    
	setPass(pipeline, "EDITOR")
		clear(pipeline, "depth")
		applyCamera(pipeline, "editor")
		executeCustomCommand(pipeline, "render_gizmos")
		--renderDebugTexts(pipeline)     
	
	renderShadowmapDebug(pipeline)
	
	print(0, 0, string.format("FPS: %.2f", getFPS(pipeline))	)
end
