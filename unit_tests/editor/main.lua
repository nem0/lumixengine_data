Engine.logInfo("Commencing editor tests");
local failed_count = 0
local tests = { 
	"all_components",
	"basic",
	"copy_paste_delete",
}

local success = Editor.runTest(Editor.editor, "unit_tests/editor/", "mismatch")
if success then
	failed_count = 1
	Engine.logError("Test mismatch.json should have failed, but it did not.");
end


for index,test in ipairs(tests) do
	local success = Editor.runTest(Editor.editor, "unit_tests/editor/", test)
	if not success then
		failed_count = failed_count + 1
		Engine.logError("Test " .. index .. " failed.");
	else
		Engine.logInfo("Test " .. index .. " succeeded.");
	end
end

Engine.logInfo("Editor tests finished, " .. tostring(failed_count) .. " tests failed.");
Editor.exit(Editor.editor, failed_count)


