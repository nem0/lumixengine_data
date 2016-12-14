local find_call = SteamUserStats.FindLeaderboard("Quickest Win")
local download_requested = false
local download_call = -1
local lb = -1
local done = false

local lb_data = {}

function onGUI()
	
	if not done then
		if not download_requested and SteamUtils.IsAPICallCompleted(find_call) then
			Engine.logError("Downloading...")
			local res = SteamUtils.GetLeaderboardFindResult(find_call)
			if res ~= nil then
				download_call = SteamUserStats.DownloadLeaderboardEntries(res.m_hSteamLeaderboard, 0, 10)
				download_requested = true
				lb = res.m_hSteamLeaderboard
			end
		end
		
		if download_requested and SteamUtils.IsAPICallCompleted(download_call) then
			local res = SteamUtils.GetLeaderboardScoresDownloaded(download_call)
			
			if res ~= nil then
				download_requested = false
				Engine.logError(tostring(res.m_cEntryCount))
				ImGui.Text("entry count " .. tostring(res.m_cEntryCount))
				for i = 0,9 do
					local entry = SteamUserStats.GetDownloadedLeaderboardEntry(res.m_hSteamLeaderboardEntries, i)
					table.insert(lb_data, entry)
				end
				done = true
			end
		end
	end
	
	ImGui.Text("lb name = " .. SteamUserStats.GetLeaderboardName(lb))
	ImGui.Text("lb entry count = " .. tostring(SteamUserStats.GetLeaderboardEntryCount(lb)))

	for _, entry in ipairs(lb_data) do
		ImGui.Text(tostring(entry.m_steamIDUser) .. " " .. tostring(entry.m_nScore) .. " " .. SteamFriends.GetFriendPersonaName(entry.m_steamIDUser))
	end
	
	if ImGui.CollapsingHeader("Friends") then
		local friend_count = SteamFriends.GetFriendCount()
		for i = 1,friend_count do
			local friend_id = SteamFriends.GetFriendByIndex(i - 1)
			local name = SteamFriends.GetFriendPersonaName(friend_id)
			local state = SteamFriends.GetFriendPersonaState(friend_id)
			if(state ~= 0) then
				ImGui.Text(name .. " state = " .. state)
				local avatar = SteamFriends.GetAvatar(i)
				ImGui.Image(avatar, 50, 50)
			end
		end
	end
end

