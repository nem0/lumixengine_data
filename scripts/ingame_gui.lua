local MENU_ACTION = 125
player_entity = -1
camera_entity = -1
Editor.setPropertyType("player_entity", Editor.ENTITY_PROPERTY)
Editor.setPropertyType("camera_entity", Editor.ENTITY_PROPERTY)

local Pages = {
	MAIN = 0,
	SETTINGS = 1
}

local gui = { shown = false, page = Pages.MAIN }
if _G["gui"] == nil then _G["gui"] = gui else gui = _G["gui"] end

function exitGame()
	if Editor.editor then
		gui.shown = false
		Editor.exitGameMode(Editor.editor)
	else
		App.exit(App.instance, 0)
	end
end

function toggleGUI()
	gui.shown = not gui.shown
	Gui.enableCursor(Gui.instance, gui.shown)
	local player_env = LuaScript.getEnvironment(g_scene_lua_script, player_entity, 0)
	if player_env then
		player_env.input_enabled = not gui.shown
	end
end
	
function main()
	if ImGui.Button("Continue", 200, 0) then toggleGUI() end
	if ImGui.Button("Settings", 200, 0) then gui.page = Pages.SETTINGS end
	if ImGui.Button("Exit", 200, 0) then exitGame() end
end

function settings()
	ImGui.Text("SETTINGS")	
	ImGui.BeginChildFrame("Settings", 500, 280)
	local camera_env = LuaScript.getEnvironment(g_scene_lua_script, camera_entity, 1)
	local changed
	local v
	if _G["game_pipeline_env"] then
		changed, v = ImGui.Checkbox("Fur", _G["game_pipeline_env"].fur_enabled)
		_G["game_pipeline_env"].fur_enabled = v
	end
	if camera_env then
		changed, v = ImGui.Checkbox("DOF", camera_env.dof_enabled)
		camera_env.dof_enabled = v
		
		changed, v = ImGui.Checkbox("Film Grain", camera_env.film_grain_enabled)
		camera_env.film_grain_enabled = v
		
		changed, v = ImGui.Checkbox("FXAA", camera_env.fxaa_enabled)
		camera_env.fxaa_enabled = v
		
		changed, v = ImGui.Checkbox("Vignette", camera_env.vignette_enabled)
		camera_env.vignette_enabled = v
		
		changed, v = ImGui.SliderFloat("Exposure", camera_env.hdr_exposure, 0.1, 20)
		camera_env.hdr_exposure = v
	end
	local player_env = LuaScript.getEnvironment(g_scene_lua_script, player_entity, 0)
	if player_env then
		changed, v = ImGui.SliderFloat("Mouse Sensitivity", player_env.MOUSE_SENSITIVITY, 0.1, 20)
		player_env.MOUSE_SENSITIVITY = v
	end
	
	changed, v = ImGui.SliderFloat("LOD", Renderer.getGlobalLODMultiplier(g_scene_renderer), 0.01, 5)
	Renderer.setGlobalLODMultiplier(g_scene_renderer, v)
	
	if ImGui.Button("Back") then gui.page = Pages.MAIN end
	ImGui.EndChildFrame()
end

_G["toggleGUI"] = toggleGUI;

function update()
	--if not gui.shown and Engine.getInputActionValue(g_engine, MENU_ACTION) > 0 then
		--toggleGUI()
	--end
	
	if not gui.shown then return end

	Gui.beginGUI(Gui.instance)
	local flags = ImGui.WindowFlags_NoMove
		| ImGui.WindowFlags_NoCollapse
		| ImGui.WindowFlags_NoResize
		| ImGui.WindowFlags_NoTitleBar
		| ImGui.WindowFlags_NoScrollbar
		| ImGui.WindowFlags_AlwaysAutoResize
	ImGui.SetNextWindowPosCenter();
	if ImGui.Begin("Menu", flags) then
		if gui.page == Pages.MAIN then main() 
		elseif gui.page == Pages.SETTINGS then settings() end
	end
	ImGui.End()
	Gui.endGUI(Gui.instance)
end

function init()
	Gui.beginGUI(Gui.instance)
	ImGui.SetStyleColor(ImGui.Col_WindowBg, 0, 0, 0, 0.0)
	ImGui.SetStyleColor(ImGui.Col_FrameBg, 0, 0, 0, 0.8)
	ImGui.SetStyleColor(ImGui.Col_Button, 0, 0, 0, 0.8)
	ImGui.SetStyleColor(ImGui.Col_ButtonActive, 0, 0, 0, 0.6)
	ImGui.SetStyleColor(ImGui.Col_ButtonHovered, 0, 0, 0, 0.6)
	Gui.endGUI(Gui.instance)
end

--Engine.addInputAction(g_engine, MENU_ACTION, Engine.INPUT_TYPE_DOWN, string.byte("M"), -1)


