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
cd scripts
devenv /edit "%1"
exit %errorlevel%
