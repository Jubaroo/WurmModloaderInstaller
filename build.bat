@echo off
setlocal EnableExtensions

rem Build the Wurm Unlimited Client Modloader installer with NSIS 3.x.
rem Usage:
rem   build.bat          release build (requestedExecutionLevel=admin)
rem   build.bat test     test build (per-user, separate registry keys)

set "ROOT=%~dp0"
set "MAKENSIS="

if exist "%ProgramFiles(x86)%\NSIS\makensis.exe" set "MAKENSIS=%ProgramFiles(x86)%\NSIS\makensis.exe"
if not defined MAKENSIS if exist "%ProgramFiles%\NSIS\makensis.exe" set "MAKENSIS=%ProgramFiles%\NSIS\makensis.exe"
if not defined MAKENSIS (
  where makensis.exe >nul 2>&1
  if not errorlevel 1 set "MAKENSIS=makensis.exe"
)

if not defined MAKENSIS (
  echo ERROR: makensis.exe was not found.
  echo Install NSIS 3.x or add it to PATH.
  exit /b 1
)

set "DEFINES="
set "VARIANT=release"
if /i "%~1"=="test" (
  set "DEFINES=/DTEST_BUILD"
  set "VARIANT=test"
)

if not exist "%ROOT%build" mkdir "%ROOT%build"

echo Building %VARIANT% installer with:
echo   "%MAKENSIS%"
"%MAKENSIS%" /V3 /WX /NOCD %DEFINES% "%ROOT%WurmModloaderInstaller.nsi"
if errorlevel 1 (
  echo.
  echo BUILD FAILED.
  exit /b 1
)

echo.
echo Build OK. SHA256:
for %%F in ("%ROOT%build\*.exe") do (
  echo   %%~nxF
  certutil -hashfile "%%F" SHA256 | findstr /v /i "hash CertUtil"
)

endlocal
exit /b 0
