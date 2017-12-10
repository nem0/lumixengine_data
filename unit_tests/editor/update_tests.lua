local tests = { 
	"all_components",
	"basic",
	"copy_paste_delete",
}

for _, test in ipairs(tests) do
	Editor.newUniverse()
	Editor.executeUndoStack([[unit_tests/editor/]] .. test .. [[.json]])
	Editor.saveUniverseAs(test, true)
end
Editor.exitWithCode(0)