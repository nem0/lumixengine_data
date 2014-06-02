call "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
set dll_name=%1
set dll_name=%dll_name:.cpp=.obj%
cd scripts
cl.exe /LDd /DEBUG /I"F:\Projects\LuxEngine\src" "%~nx1" /link /DYNAMICBASE "kernel32.lib" "user32.lib" "core.lib" "engine.lib" /DEBUG /LIBPATH:"F:\Projects\LuxEngine\bin\Win32_Debug"
exit %errorlevel%
