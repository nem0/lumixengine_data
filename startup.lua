App.loadUniverse("universes/player.unv")
while Engine.hasFilesystemWork(g_engine) do Engine.processFilesystemWork(g_engine) end
Engine.startGame(g_engine, App.universe)