Gui.loadFile(Gui.instance, "gui/button.tb.txt")

local MENU_ACTION = 125
Engine.addInputAction(g_engine, MENU_ACTION, Engine.INPUT_TYPE_DOWN, string.byte("M"), -1)

function update()
	if Engine.getInputActionValue(g_engine, MENU_ACTION) > 0 then
		Gui.showGUI(Gui.instance, not Gui.isGUIShown(Gui.instance))
	end
end

function onGUI()
	if ImGui.Button("Toggle") then
		Gui.showGUI(Gui.instance, not Gui.isGUIShown(Gui.instance))
	end
	if ImGui.Button("Reload") then
		Gui.loadFile(Gui.instance, "gui/button.tb.txt")
	end
end