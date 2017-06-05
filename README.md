![Weave Logo](http://iweave.com/img/weave_logo.png)
## Visit us at [our site](http://iweave.com)

## This repository is for Weave version 1.9 ([Wiki](http://info.iweave.com/projects/weave/wiki)).

## To View a running version of Weave click [here](http://weaveteam.github.io/Weave-Binaries/weave.html)

## For some examples of what you can do with Weave click [here](http://iweave.com/documentation.html#examples)

# License
Weave is distributed under the [MPL-2.0](https://www.mozilla.org/en-US/MPL/2.0/) license.

# Download
[Installation Guide](http://info.iweave.com/projects/weave/wiki/Deployment_Guide)

[Milestone 1.9.45](https://github.com/WeaveTeam/Weave-Binaries/archive/milestone-1.9.45.zip)

[Nightly build](https://github.com/WeaveTeam/Weave-Binaries/zipball/master)

# Documentation
You can find the Admin Console User Guide [here](http://info.iweave.com/projects/weave/wiki/Weave_Administration_Console_User_Guide)

Weave supports integration from multiple data sources including: **CSV, GeoJSON, SHP/DBF, CKAN**  
  
Additional developer documentation can be found [here](http://WeaveTeam.github.com/Weave-Binaries/asdoc/)

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

