local MENU_ACTION = 125
player_entity = -1
camera_entity = -1
Editor.setPropertyType("player_entity", Editor.ENTITY_PROPERTY)
Editor.setPropertyType("camera_entity", Editor.ENTITY_PROPERTY)

function toggleGUI()
	local is_gui = Gui.isGUIShown(Gui.instance)
	local player_env = LuaScript.getEnvironment(g_scene_lua_script, player_entity, 0)
	if player_env then
		player_env.input_enabled = is_gui
	end
	Gui.showGUI(Gui.instance, not is_gui)
end

function update()
	if Engine.getInputActionValue(g_engine, MENU_ACTION) > 0 then
		toggleGUI()
	end
end

function onContinue()
	toggleGUI()
end

function onExit()
	if Editor.editor then
		Gui.showGUI(Gui.instance, false)
		Editor.exitGameMode(Editor.editor)
	end
end

function onOptions()
	Gui.loadFile(Gui.instance, "gui/options.tb.txt")
end

function onOptionFXAA()
	local camera_env = LuaScript.getEnvironment(g_scene_lua_script, camera_entity, 1)
	if camera_env then
		camera_env.fxaa_enabled = not camera_env.fxaa_enabled
	end

end

function onOptionDOF()
	local camera_env = LuaScript.getEnvironment(g_scene_lua_script, camera_entity, 1)
	if camera_env then
		camera_env.dof_enabled = not camera_env.dof_enabled
	end
end

function onOptionFilmGrain()
	local camera_env = LuaScript.getEnvironment(g_scene_lua_script, camera_entity, 1)
	if camera_env then
		camera_env.film_grain_enabled = not camera_env.film_grain_enabled
	end
end

function onOptionVignette()
	local camera_env = LuaScript.getEnvironment(g_scene_lua_script, camera_entity, 1)
	if camera_env then
		camera_env.vignette_enabled = not camera_env.vignette_enabled
	end
end

function onGUI()
	if ImGui.Button("Toggle") then
		Gui.showGUI(Gui.instance, not Gui.isGUIShown(Gui.instance))
	end
	if ImGui.Button("Reload") then
		Gui.loadFile(Gui.instance, "gui/ingame_menu.tb.txt")
	end
end

function onOptionExposure()
	local val = Gui.getSliderValue(Gui.instance, "option_exposure")
	local camera_env = LuaScript.getEnvironment(g_scene_lua_script, camera_entity, 1)
	if camera_env then
		camera_env.hdr_exposure = val / 10.0
	end
end

function onDestroy()
	if Gui.isGUIShown(Gui.instance) then toggleGUI() end
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "continue")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "exit")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "options")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "options_back")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "option_dof")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "option_fxaa")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "option_vignette")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "option_film_grain")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CHANGED, "option_exposure")
end

Gui.loadFile(Gui.instance, "gui/ingame_menu.tb.txt")
Gui.showGUI(Gui.instance, false)

Engine.addInputAction(g_engine, MENU_ACTION, Engine.INPUT_TYPE_DOWN, string.byte("M"), -1)

Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "continue", onContinue)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "exit", onExit)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "options", onOptions)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "option_dof", onOptionDOF)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "option_fxaa", onOptionFXAA)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "option_vignette", onOptionVignette)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "option_film_grain", onOptionFilmGrain)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CHANGED, "option_exposure", onOptionExposure)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "options_back", function () 
	Gui.loadFile(Gui.instance, "gui/ingame_menu.tb.txt")
end)

