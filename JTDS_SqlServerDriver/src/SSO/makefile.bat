REM To build first set JAVA_HOME to the root directory of your jdk 
REM (like c:\program files\java\jdk1.5.0) then call this file with the
REM build arguement
REM Examples:
REM makefile "ntlmauth - Win32 Release"
REM makefile "ntlmauth - x64 Release"
REM makefile "ntlmauth - IA64 Release"


@echo off
set JAVA_INCLUDES=;%JAVA_HOME%\include;%JAVA_HOME%\include\win32
set INCLUDE=%JAVA_INCLUDES%;%INCLUDE%
set BUILD_CONFIG=%1
if "" == "%BUILD_CONFIG%" set BUILD_CONFIG="ntlmauth - Win32 Release"
NMAKE /f "ntlmauth.mak" CFG=%BUILD_CONFIG%
