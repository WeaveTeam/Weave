@echo off

if "%JAVA_HOME%" == "" goto error

set _javatemp=%JAVA_HOME%

echo.
echo Building jTDS...
echo ----------------

IF NOT %JAVA_HOME:~-1% == \ set JAVA_HOME=%JAVA_HOME%\

set LOCALCLASSPATH=%JAVA_HOME%lib\tools.jar
REM set LOCALCLASSPATH=%LOCALCLASSPATH%;%ANT_HOME%\lib\ant.jar
REM set LOCALCLASSPATH=%LOCALCLASSPATH%;%ANT_HOME%\lib\optional.jar
for %%i in (lib\*.jar) do call lcp.bat %%i

echo.
echo Building with classpath %LOCALCLASSPATH%

echo.
echo Starting Ant...

"%JAVA_HOME%bin\java.exe" -Dant.home="." -classpath "%LOCALCLASSPATH%" org.apache.tools.ant.Main %1 %2 %3 %4 %5

goto end

:error

echo "ERROR: JAVA_HOME not found in your environment."
echo.
echo "Please, set the JAVA_HOME variable in your environment to match the"
echo "location of the Java Virtual Machine you want to use."

:end

set LOCALCLASSPATH=
set ANT_HOME=
set JAVA_HOME=%_javatemp%
