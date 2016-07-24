Engine.logInfo("Commencing editor tests");
local failed_count = 0
local tests = { 
	"unit_tests/editor/joints",
	"unit_tests/editor/particles", 
	"unit_tests/editor/simple", 
	"unit_tests/editor/terrain" 
}

local success = Editor.runTest(Editor.editor, "unit_tests/editor/mismatch.json", "unit_tests/editor/mismatch.unv")
if success then
	failed_count = 1
	Engine.logError("Test mismatch.json should have failed, but it did not.");
end


for index,test in ipairs(tests) do
	local success = Editor.runTest(Editor.editor, test .. ".json", test .. ".unv")
	if not success then
		failed_count = failed_count + 1
		Engine.logError("Test " .. index .. " failed.");
	else
		Engine.logInfo("Test " .. index .. " succeeded.");
	end
end

Engine.logInfo("Editor tests finished, " .. tostring(failed_count) .. " tests failed.");
Editor.exit(Editor.editor, failed_count)


