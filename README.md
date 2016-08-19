![Weave Logo](http://iweave.com/img/weave_logo.png)
## Visit us at [our site](http://iweave.com)

## To View a running version of Weave click [here](http://iweave.com/demo.html)

##For some examples of what you can do with Weave click [here](http://iweave.com/documentation.html#examples)

#License
Weave 2 is distributed under the [MPL-2.0](https://www.mozilla.org/en-US/MPL/2.0/) license.

#Download
[Windows](http://example.iweave.com/WeaveSetup.exe) [Installation Guide](http://iweave.com/assets/getstarted/WeaveInstallationGuideForWindows.pdf)  
[Mac](http://example.iweave.com/WeaveSetup.zip) [Installation Guide](http://iweave.com/assets/getstarted/WeaveInstallationGuideForMac.pdf)  
[Linux](http://example.iweave.com/WeaveSetup.exe) [Installation Guide](http://iweave.com/assets/getstarted/WeaveInstallationGuideForLinux.pdf)

#Documentation
You can find the Admin Console User Guide [here](http://iweave.com/assets/documentation/WeaveUserGuide-AdminConsole.pdf)

Weave supports integration from multiple data sources including: **CSV, GeoJSON, SHP/DBF, CKAN**  
  
Additional developer documentation can be found [here](http://WeaveTeam.github.com/Weave-Binaries/asdoc/)

#To devlop with Weave  
##Install WeaveJS
* npm install
* nmp run compile
 
##Install WeaveApp
* cd WeaveApp
* npm install
* npm run compile

Nightly build: https://github.com/WeaveTeam/Weave-Binaries/zipball/master

Components in this repository:

 * WeaveAPI: ActionScript interface classes.
 * WeaveCore: Core sessioning framework.
 * WeaveData: Data framework. Non-UI features.
 * WeaveUISpark: User interface classes (Spark components).
 * WeaveUI: User interface classes (Halo components).
 * WeaveClient: Flex application for Weave UI.
 * WeaveDesktop: Adobe AIR application front-end for Weave UI.
 * WeaveAdmin: Flex application for admin activities.
 * WeaveServletUtils: Back-end Java webapp libraries.
 * WeaveServices: Back-end Java webapp for Admin and Data server features.
 * GeometryStreamConverter: Java library for converting geometries into a streaming format. Binary included in WeaveServices/lib.
 * JTDS_SqlServerDriver: Java library for handling connections to Microsoft SQL Server. Binary included in WeaveServletUtils/lib.

The bare minimum you need to build Weave is [Flex 4.5.1.A](http://fpdownload.adobe.com/pub/flex/sdk/builds/flex4.5/flex_sdk_4.5.1.21328A.zip) and [Java EE](http://www.oracle.com/technetwork/java/javaee/downloads/index.html).  However, we recommend the following setup: http://info.oicweave.org/projects/weave/wiki/Development_environment_setup

To build the projects on the command line, use the **build.xml** Ant script. To create a ZIP file for deployment on another system (much like the nightlies,) use the **dist** target.

See install-linux.md for detailed linux install instructions.

