# Weave


Weave is an open source web-based visualization platform, written in Actionscript and Java.

## Requirements

### Weave client

* Internet browser
* Adobe Flash plugin 10.0+

### Weave server

* Windows, Linux or Unix based OS
* Java Servlet Container (Oracle Glassfish 3+, Apache Tomcat 6+)
* MySQL, PostgreSQL database server

## Installation

### Linux

1. Install the following packages (Ubuntu/Debian):
 * sun-java6-jdk
 * ant
 * tomcat6
 * git
 * junit4
 * libservlet2.4-java
2. Download the [Adobe Flex 3.5 SDK](http://opensource.adobe.com/wiki/display/flexsdk/Download+Flex+3) and extract it to a directory in your home dir, something like 

 ``~/bin/flex``.

3. Add the following line to your ``.bashrc`` or equivalent, modified as appropriate to the path chosen in step 2:

 ``export FLEX_HOME=~/bin/flex``

 Additionally, run this line in your working terminal, or open a fresh terminal to ensure the environment variable is set. 
4. Clone the Weave git repository either read-only:
 
 ``git clone git://github.com/IVPR/Weave.git``
 
 Or, if you are a contributor:

 ``git clone git@github.com:IVPR/Weave.git``
5. Enter the resulting Weave directory, and the subdirectory it contains named ``WeaveClient.``
6. Edit the ``buildall.xml`` file, being sure to follow the directions provided in the comment at the beginning of the file, being sure to set ``WEAVE_DOCROOT`` to some path writable by your user.
7. Run 

 ``ant -f buildall.xml``

8. Open a new file at /etc/tomcat6/Catalina/localhost/weave.xml, ie

 ``sudo vim /etc/tomcat6/Catalina/localhost/weave.xml``
   
 And add the following line:
 
 ``<Context path="/weave" docBase="/home/user/pub/app">``
	
 Modifying ``docBase`` as appropriate. 
9. Restart the tomcat service as appropriate for your distribution. For example, on Ubuntu/Debian:
 ``/etc/init.d/tomcat6 restart``
10. Open your browser and enter 

 ``"http://localhost:8080/weave"`` 

 to test.