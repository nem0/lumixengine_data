 rmdir /S /Q compiled
 del /Q shader_test.log
 mkdir compiled
 cd..
 "shaders/shaderc.exe" -f shaders/rigid_fs.sc -o shaders/compiled/rigid_MAIN0_fs.shb --depends --platform windows --type fragment --profile ps_4_0 -D MAIN > shaders/shader_test.log 2>&1
 