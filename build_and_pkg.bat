@echo off

REM Initial cleanup.
pushd %~dp0 && (git clean -xfd && git submodule foreach --recursive git clean -xfd & popd)
if '%errorlevel%' neq '0' exit /b 1

REM Win64
pushd %~dp0 && (perl external\buildscripts\build_win_no_cygwin.pl --build=1 --clean=1 --artifact=1 --arch32=0 --forcedefaultbuilddeps=1 --stevedorebuilddeps=1 & popd)
if '%errorlevel%' neq '0' exit /b 1
pushd %~dp0 && (git clean -xfd -e /builds/ && git submodule foreach --recursive git clean -xfd & popd)
if '%errorlevel%' neq '0' exit /b 1

REM Win32
pushd %~dp0 && (perl external\buildscripts\build_win_no_cygwin.pl --build=1 --clean=1 --artifact=1 --arch32=1 --forcedefaultbuilddeps=1 --stevedorebuilddeps=1 & popd)
if '%errorlevel%' neq '0' exit /b 1
pushd %~dp0 && (git clean -xfd -e /builds/ && git submodule foreach --recursive git clean -xfd & popd)
if '%errorlevel%' neq '0' exit /b 1

REM Linux64
pushd %~dp0 && (wsl --exec bash -c "export ASAN_OPTIONS=detect_leaks=0 && perl external/buildscripts/build.pl --build=1 --clean=1 --artifact=1 --arch32=0 --forcedefaultbuilddeps=1 --stevedorebuilddeps=1" & popd)
if '%errorlevel%' neq '0' exit /b 1

REM Skip packaging into Unity source if not specified.
if '%UNITY_SRC_DIR%' equ '' (
  echo Skipping packaging into Unity source folder, set UNITY_SRC_DIR to your Unity source path.
  goto :EOF
)

REM Use 7zip to assemble a .7z archive of the generated Win32, Win64, and Linux builds.
rmdir /s /q %~dp0tmp
%UNITY_SRC_DIR%\External\7z\win64\7za.exe x -aoa "-o%~dp0tmp" %UNITY_SRC_DIR%\External\MonoBleedingEdge\builds.7z
robocopy /E %~dp0builds %~dp0tmp
rmdir /s /q %UNITY_SRC_DIR%\Bonfire\MonoBleedingEdgeAsan
mkdir %UNITY_SRC_DIR%\Bonfire\MonoBleedingEdgeAsan
%UNITY_SRC_DIR%\External\7z\win64\7za.exe a -mm=ZSTD -mx=19 %UNITY_SRC_DIR%\Bonfire\MonoBleedingEdgeAsan\builds.7z %~dp0tmp\.
rmdir /s /q %~dp0tmp
