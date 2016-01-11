Editor.logInfo(g_editor, "Commencing editor tests");
local failed_count = 0
local tests = { 
	"unit_tests/editor/simple", 
	"unit_tests/editor/terrain" 
}

local success = Editor.runTest(g_editor, "unit_tests/editor/mismatch.json", "unit_tests/editor/mismatch.unv")
if success then
	failed_count = 1
	Editor.logError(g_editor, "Test mismatch.json should have failed, but it did not.");
end


for index,test in ipairs(tests) do
	local success = Editor.runTest(g_editor, test .. ".json", test .. ".unv")
	if not success then
		failed_count = failed_count + 1
		Editor.logError(g_editor, "Test " .. index .. " failed.");
	else
		Editor.logError(g_editor, "Test " .. index .. " succeeded.");
	end
end

Editor.logInfo(g_editor, "Editor tests finished, " .. tostring(failed_count) .. " tests failed.");
Editor.exit(g_editor, failed_count)


