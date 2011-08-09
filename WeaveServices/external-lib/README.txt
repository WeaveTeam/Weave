Installation instructions for Weave server-side R support

1.	Install R (Latest version as of this document is R.2.13.1)

2.	Download rJava binary package from http://cran.r-project.org/web/packages/rJava/index.html

3.	Place the rJava Package in the R library folder
		Example:
		C:\Program Files (x86)\R\R-2.13.1\library\

4.	Create R_HOME environment variable pointing to the R installation folder.
		Example:
		C:\Program Files (x86)\R\R-2.13.1\

5.	Append two folders to the PATH environment variable for R.dll and jri.dll.
		Example:
		C:\Program Files (x86)\R\R-2.13.1\bin\i386\
		C:\Program Files (x86)\R\R-2.13.1\library\rJava\jri\

6.	Copy the JRI.jar, JRIEngine.jar, and REngine.jar files from the rJava/jri folder into the Tomcat lib folder and restart Tomcat.
		Example:
		C:\Program Files (x86)\Apache Software Foundation\Tomcat 6.0\lib\JRI.jar
		C:\Program Files (x86)\Apache Software Foundation\Tomcat 6.0\lib\JRIEngine.jar
		C:\Program Files (x86)\Apache Software Foundation\Tomcat 6.0\lib\REngine.jar
		Notes:
			If these JAR files are located elsewhere, you will get errors such as "java.lang.UnsatisfiedLinkError" and "Library is already loaded in another ClassLoader".
			If you copy these JAR files without setting the R_HOME or PATH environment variables, the server will crash when attempting to use R.

7.	Restart your computer so the new values in the environment variables will be used by Tomcat.