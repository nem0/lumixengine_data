if exist "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" (
	call "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
) else (
	call "C:\Program Files\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
)
set dll_name=%1
set dll_name=%dll_name:.cpp=.obj%
cd scripts
cl.exe /LDd /DEBUG /I"D:\Projects\LuxEngine\src" "%1" /link /DYNAMICBASE "kernel32.lib" "user32.lib" "core.lib" "engine.lib"  /DEBUG /LIBPATH:"D:\Projects\LuxEngine\bin\Win32_Debug"
REM exit %errorlevel%
