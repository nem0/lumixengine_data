local MENU_ACTION = 125
player_entity = -1
Editor.setPropertyType("player_entity", Editor.ENTITY_PROPERTY)

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

function onGUI()
	if ImGui.Button("Toggle") then
		Gui.showGUI(Gui.instance, not Gui.isGUIShown(Gui.instance))
	end
	if ImGui.Button("Reload") then
		Gui.loadFile(Gui.instance, "gui/button.tb.txt")
	end
end

function onDestroy()
	if Gui.isGUIShown(Gui.instance) then toggleGUI() end
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "continue")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "exit")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "options")
	Gui.unregisterEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "options_back")
end

Gui.loadFile(Gui.instance, "gui/button.tb.txt")
Gui.showGUI(Gui.instance, false)

Engine.addInputAction(g_engine, MENU_ACTION, Engine.INPUT_TYPE_DOWN, string.byte("M"), -1)

Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "continue", onContinue)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "exit", onExit)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "options", onOptions)
Gui.registerEvent(Gui.instance, Gui.EVENT_TYPE_CLICK, "options_back", function () 
	Gui.loadFile(Gui.instance, "gui/button.tb.txt")
end)

