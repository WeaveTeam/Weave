# End-user requirements

* Adobe Flash Player 10.0+

# Server requirements

* Java Servlet Container (Tomcat, Glassfish, or Jetty)
* MySQL or PostgreSQL

# Installation

1. Install the following packages (Ubuntu/Debian):
 * oracle-java7-jdk
 * ant
 * tomcat7
 * git
 * junit4
 * libservlet2.5-java
2. Download the [Adobe Flex 4.5.1A SDK](http://fpdownload.adobe.com/pub/flex/sdk/builds/flex4.5/flex_sdk_4.5.1.21328A.zip) and extract it to a directory in your home directory, something like

 ``~/bin/flex``.

3. Add the following lines to your ``.bashrc`` or equivalent, modified as appropriate to the path chosen in step 2:

 ``export FLEX_HOME=~/bin/flex``
 ``export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")``

 Additionally, run this line in your working terminal, or open a fresh terminal to ensure the environment variable is set. 
4. Clone the Weave git repository either read-only:
 
 ``git clone git://github.com/IVPR/Weave.git``
 
 Or, if you are a contributor:

 ``git clone git@github.com:IVPR/Weave.git``
5. Enter the resulting Weave directory.
6. Edit the ``build.properties`` file. Be sure to set ``WEAVE_DOCROOT`` to some path writable by your user, and to set the various `*_SWF` variables to match the names of those present in your version of the Flex SDK. (The default values for the `*_SWF` variables are set with Flex 4.5.1A in mind.)
7. Run 

 ``ANT_OPTS='-XX:MaxPermSize=1024m -Xms256M -Xmx512M' ant install``

8. Open a new file at /etc/tomcat6/Catalina/localhost/weave.xml, ie

 ``sudo vim /etc/tomcat7/Catalina/localhost/weave.xml``
   
 And add the following line:
 
 ``<Context path="/weave" docBase="/home/user/pub/app">``
	
 Modifying ``docBase`` to match the value of WEAVE_DOCROOT.
8. Copy ``WeaveServices.war`` from the source directory into ``/var/lib/tomcat7/webapps``.
9. Restart the tomcat service as appropriate for your distribution. For example, on Ubuntu/Debian:
 ``sudo service tomcat7 restart``
10. Open your browser and enter 

 ``"http://localhost:8080/weave/weave.html"`` 
 		or
 ``"http://localhost:8080/weave/AdminConsole.html"`` 

 to test.

Alternatively, the 'dist' target may be used to build a zip file containing both the WeaveServices.war and the Weave ROOT folder so you can deploy it on another system.
