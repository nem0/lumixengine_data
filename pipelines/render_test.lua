common = require "pipelines/common"
ctx = { pipeline = this }


shadowmap_uniform = createUniform(this, "u_texShadowmap")
texture_uniform = createUniform(this, "u_texture")
blur_material = Engine.loadResource(g_engine, "shaders/blur.mat", "material")
screen_space_material = Engine.loadResource(g_engine, "shaders/screen_space.mat", "material")
ssao_material = Engine.loadResource(g_engine, "shaders/ssao.mat", "material")
common.init(ctx)
common.initShadowmap(ctx)


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
	common.shadowmap(ctx, "editor")
	main(this)
	common.particles(ctx, "editor")
	pointLight(this)		

	postprocessCallback(ctx.pipeline, "editor")
end

