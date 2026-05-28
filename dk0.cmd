@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

SET DK_PROJECT_DIR=%~dp0
SET DK_VER=2.4.2.179
SET DK_CKSUM_WINDOWS_X86_64=d086d7bb664452a6cd2692ca5e030a985b75b9d3b08d8a59c66edcfc08b1b56f

SET DK_DATA_HOME=%LOCALAPPDATA%\Programs\dk0
SET DK_EXEDIR=%DK_DATA_HOME%\dk0exe-%DK_VER%-windows_x86_64
IF NOT EXIST "!DK_EXEDIR!" MKDIR "!DK_EXEDIR!"
SET DK_EXE=!DK_EXEDIR!\dk0.exe

IF NOT EXIST "!DK_EXE!" (
  IF NOT EXIST "%TEMP%\%DK_CKSUM_WINDOWS_X86_64%" MKDIR "%TEMP%\%DK_CKSUM_WINDOWS_X86_64%"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest 'https://gitlab.com/api/v4/projects/60486861/packages/generic/dk0/%DK_VER%/dk0-windows_x86_64.exe' -OutFile '%TEMP%\%DK_CKSUM_WINDOWS_X86_64%\dk0.exe'" >NUL
  XCOPY "%TEMP%\%DK_CKSUM_WINDOWS_X86_64%\dk0.exe" "!DK_EXEDIR!" /v /g /i /r /n /y /j >NUL
)

SET "_CELL=%DK_PROJECT_DIR%"
SET "_CELL=%_CELL:\=/%"
"%DK_EXE%" -isystem "%DK_PROJECT_DIR%\etc\dk\i" --cell "dk0=%_CELL%" %*
EXIT /B %ERRORLEVEL%
