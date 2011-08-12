call build.bat
java -Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,address=2000,server=y,suspend=n -classpath build\classes;lib\junit.jar %1 %2 %3 %4 %5 %6 %7 %8 %9
