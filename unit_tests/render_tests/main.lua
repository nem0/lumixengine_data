local tests = { 
	"fog", 
	"height_fog", 
	"hidden_mesh", 
	"light_color", 
	"parallax", 
	"pointlight", 
	"pointlight_shadows", 
	"shadow",
	"simple",
	"simple_terrain",
	"spotlight"
}

local function waitForLoad()
	while Engine.hasFilesystemWork(g_engine) do Engine.processFilesystemWork(g_engine) end
end


local different_files = 0
for key, value in pairs(tests) do
	App.frame(App.instance)
	App.frame(App.instance)
	App.loadUniverse(App.instance, "unit_tests/render_tests/"..value..".unv")
	waitForLoad()
	
	App.frame(App.instance)
	App.frame(App.instance)
	App.frame(App.instance)
	App.frame(App.instance)
	local out_tga = "unit_tests/render_tests/"..value.."_res.tga";
	local template_tga = "unit_tests/render_tests/"..value..".tga"
	Renderer.makeScreenshot(g_scene_renderer, out_tga)
	App.frame(App.instance)
	App.frame(App.instance)
	App.frame(App.instance)
	App.frame(App.instance)
	dif = Renderer.compareTGA(g_scene_renderer, out_tga, template_tga, 10)
	local log_msg = "Universe unit_tests/render_tests/" .. value .. ".unv => difference " .. tostring(dif)
	if dif > 100 then
		different_files = different_files + 1
		Engine.logError(log_msg)
	else
		Engine.logInfo(log_msg)
	end
	App.frame(App.instance)
end

App.exit(App.instance, different_files)
	
