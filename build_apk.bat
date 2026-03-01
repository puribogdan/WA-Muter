@echo off
setlocal
call "%~dp0build_release_fast.bat" %*
set EXIT_CODE=%ERRORLEVEL%
endlocal & exit /b %EXIT_CODE%
