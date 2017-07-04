	local in_dir = [[C:\projects\OpenFBX\runtime\models\]]
	for filename in io.popen([[dir "]] .. in_dir .. [[" /b]]):lines() do 
		if string.sub(filename:lower(),-string.len(".fbx"))==".fbx" then
			ImportFBX.clearSources()
			ImportFBX.addSource(in_dir .. filename)
			ImportFBX.setParams({ output_dir = [[C:\projects\lumixengine_data\models\test\]] })

			for i = 0, ImportFBX.getAnimationsCount() - 1 do
				ImportFBX.setAnimationParams(i, {import = true})
			end

			ImportFBX.import()
		end
	end

--[[
ImportAsset.addSource("C:\projects\OpenFBX\runtime\c.fbx")
ImportAsset.setParams({ output_dir = "C:\projects\lumixengine_data\models\test\" })

for i = 0, ImportAsset.getAnimationsCount() - 1 do
	ImportAsset.setAnimationParams(i, {import = false})
end

ImportAsset.import()

]]--