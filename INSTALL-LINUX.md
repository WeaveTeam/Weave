# End-user requirements

* Adobe Flash Player 10.0+

# Server requirements

* Java Servlet Container (Tomcat or Glassfish)
* MySQL or PostgreSQL

# Installation

1. Install the following packages (Ubuntu/Debian):
 * sun-java6-jdk
 * ant
 * tomcat6
 * git
 * junit4
 * libservlet2.4-java
2. Download the [Adobe Flex 3.6 SDK](http://opensource.adobe.com/wiki/display/flexsdk/Download+Flex+3) and extract it to a directory in your home dir, something like 

 ``~/bin/flex``.

3. Add the following line to your ``.bashrc`` or equivalent, modified as appropriate to the path chosen in step 2:

 ``export FLEX_HOME=~/bin/flex``

 Additionally, run this line in your working terminal, or open a fresh terminal to ensure the environment variable is set. 
4. Clone the Weave git repository either read-only:
 
 ``git clone git://github.com/IVPR/Weave.git``
 
 Or, if you are a contributor:

 ``git clone git@github.com:IVPR/Weave.git``
5. Enter the resulting Weave directory, and the subdirectory it contains named ``WeaveClient.``
6. Edit the ``buildall.xml`` file. Be sure to set ``WEAVE_DOCROOT`` to some path writable by your user, and to set SDK_VERSION as appropriate for the SDK version. More information can be found in the comments of the file.
7. Run 

 ``ANT_OPTS=-XX:MaxPermSize=1024m ant -f buildall.xml install``

8. Open a new file at /etc/tomcat6/Catalina/localhost/weave.xml, ie

 ``sudo vim /etc/tomcat6/Catalina/localhost/weave.xml``
   
 And add the following line:
 
 ``<Context path="/weave" docBase="/home/user/pub/app">``
	
 Modifying ``docBase`` as appropriate. 
8. Copy ``WeaveServices.war`` from the source directory into ``/var/lib/tomcat6/webapps``.
9. Restart the tomcat service as appropriate for your distribution. For example, on Ubuntu/Debian:
 ``/etc/init.d/tomcat6 restart``
10. Open your browser and enter 

 ``"http://localhost:8080/weave"`` 

 to test.
