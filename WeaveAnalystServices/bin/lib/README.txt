Installation instructions for Weave server-side R support

1.	Install R (Latest version as of this document is R.2.13.1 which includes rJava library as part of it)

For older version do steps 2 and 3, rJava has to be manually added.

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


6.	Restart your computer so the new values in the environment variables will be used by Tomcat.