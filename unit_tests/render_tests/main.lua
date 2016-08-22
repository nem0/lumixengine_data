local tests = {
	{"colored_material", 10},
	{"decals", 10},
	{"fog", 10}, 
	{"godrays", 10}, 
	{"height_fog", 10}, 
	{"hidden_mesh", 10}, 
	{"light_color", 10}, 
	{"parallax", 10}, 
	{"pointlight", 10}, 
	{"pointlight_shadows", 10}, 
	{"shadow", 10},
	{"simple", 10},
	{"simple_terrain", 10},
	{"skinned", 10},
	{"spotlight", 10},
	{"ssao", 20} -- ssao uses random rotation => higher tolerance
}

local function waitForLoad()
	while Engine.hasFilesystemWork(g_engine) do Engine.processFilesystemWork(g_engine) end
end


local different_files = 0
for key, value in pairs(tests) do
	App.frame(App.instance)
	App.frame(App.instance)
	App.loadUniverse(App.instance, "unit_tests/render_tests/"..value[1]..".unv")
	waitForLoad()
	
	App.frame(App.instance)
	App.frame(App.instance)
	App.frame(App.instance)
	App.frame(App.instance)
	local out_tga = "unit_tests/render_tests/"..value[1].."_res.tga";
	local template_tga = "unit_tests/render_tests/"..value[1]..".tga"
	Renderer.makeScreenshot(g_scene_renderer, out_tga)
	App.frame(App.instance)
	App.frame(App.instance)
	App.frame(App.instance)
	App.frame(App.instance)
	--if value[1] == "ssao" then while true do App.frame(App.instance) end end
	dif = Renderer.compareTGA(g_scene_renderer, out_tga, template_tga, value[2], true)
	local log_msg = "Universe unit_tests/render_tests/" .. value[1] .. ".unv => difference " .. tostring(dif)
	if dif > 5000 then
		different_files = different_files + 1
		Engine.logError(log_msg)
	else
		Engine.logInfo(log_msg)
	end
	App.frame(App.instance)
end

App.exit(App.instance, different_files)
	
