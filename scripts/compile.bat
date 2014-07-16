if exist "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" (
	call "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
) else (
	call "C:\Program Files\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
)
set dll_name=%1
set dll_name=%dll_name:.cpp=.obj%
cd scripts
cl.exe /LDd /DEBUG /I"D:\Projects\LumixEngine\src" "%1" /link /DYNAMICBASE "kernel32.lib" "user32.lib" "core.lib" "engine.lib" "physics.lib"  /DEBUG /LIBPATH:"D:\Projects\LumixEngine\bin\Win32_Release"
exit %errorlevel%
