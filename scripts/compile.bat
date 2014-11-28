@echo off
if exist "C:\Program Files\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" (
	call "C:\Program Files\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86
	echo "Using Visual Studio 2013"
) else ( 
	if exist "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" (
		call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86
		echo "Using Visual Studio 2013"
	) else ( 
		if exist "C:\Program Files\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" (
			call "C:\Program Files\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
			echo "Using Visual Studio 2012"	
		) else (
			call "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
			echo "Using Visual Studio 2012"
		)
	)
)
set dll_name=%1
set dll_name=%dll_name:.cpp=.obj%
cd scripts
cl.exe /LDd /I"D:\Projects\LumixEngine\src" "%1" /link /DYNAMICBASE "kernel32.lib" "user32.lib" "core.lib" "engine.lib" "physics.lib"  /LIBPATH:"D:\Projects\LumixEngine\bin\Win32_Release"
exit %errorlevel%
