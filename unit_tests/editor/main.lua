Editor.logInfo(Editor.editor, "Commencing editor tests");
local failed_count = 0
local tests = { 
	"unit_tests/editor/simple", 
	"unit_tests/editor/terrain" 
}

local success = Editor.runTest(Editor.editor, "unit_tests/editor/mismatch.json", "unit_tests/editor/mismatch.unv")
if success then
	failed_count = 1
	Editor.logError(Editor.editor, "Test mismatch.json should have failed, but it did not.");
end


for index,test in ipairs(tests) do
	local success = Editor.runTest(Editor.editor, test .. ".json", test .. ".unv")
	if not success then
		failed_count = failed_count + 1
		Editor.logError(Editor.editor, "Test " .. index .. " failed.");
	else
		Editor.logInfo(Editor.editor, "Test " .. index .. " succeeded.");
	end
end

Editor.logInfo(Editor.editor, "Editor tests finished, " .. tostring(failed_count) .. " tests failed.");
Editor.exit(Editor.editor, failed_count)


