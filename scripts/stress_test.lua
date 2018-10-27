local s = 50
for i = 1,s do
for j = 1,s do
for k = 1,s do

Engine.createEntityEx(g_engine, g_universe, { position = {i *3, j * 3, k * 3}, model_instance = { Source = [[assets/models/cube.fbx]]  })

end
end
end