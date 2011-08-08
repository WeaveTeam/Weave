Install R.2.13.1
Download rJava Package (windows binaries in Zip format) from (http://cran.r-project.org/web/packages/rJava/index.html)
Place the rJava Package in "say in my Machine" (C:\Program Files (x86)\R\R-2.13.1\library)

To avoid "Cannot find Java Native library" error
	Create R_HOME environment varibale [C:\Program Files (x86)\R\R-2.13.1]
	Append to PATH environemnt variable for R.dll and jri.dll [C:\Program Files (x86)\R\R-2.13.1\bin\i386;C:\Program Files (x86)\R\R-2.13.1\library\rJava\jri]

Now to avoid  "java.lang.UnsatisfiedLinkError" along with "Library is already loaded in another ClassLoader"
	Add the JRI,JRIEngine, REngine  jar files in Tomacat library folder
	"say in my Machine"
	C:\Program Files (x86)\Apache Software Foundation\Tomcat 6.0\lib\JRI.jar
	C:\Program Files (x86)\Apache Software Foundation\Tomcat 6.0\lib\JRIEngine.jar
	C:\Program Files (x86)\Apache Software Foundation\Tomcat 6.0\lib\REngine.jar
	
	Change in Eclipse Java Build Path for those libraries
	
	
	