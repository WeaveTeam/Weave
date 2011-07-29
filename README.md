Weave: Web-based Analysis and Visualization Environment - http://www.oicweave.org/

Issue Tracker & Wiki: http://bugs.oicweave.org/

Developer documentation: http://ivpr.github.com/Weave/asdoc/

Nightly build: https://github.com/IVPR/Weave-Binaries/zipball/master

Components in this repository:

 * WeaveAPI: MPL tri-license, ActionScript interface classes
 * WeaveCore: GPLv3 license, core sessioning framework
 * WeaveData: GPLv3 license, columns related to loading data and other non-UI features.
 * WeaveUI: GPLv3 license, user interface classes
 * WeaveClient: GPLv3 license, Flex client application for visualization environment
 * WeaveAdmin: GPLv3 license, Flex application for admin activities
 * WeaveServices: GPLv3 license, back-end Java webapp for Admin and Data server features
 * GeometryStreamConverter: GPLv3 license, Java library for converting geometries into a streaming format

The bare minimum you need to build Weave is [Flex 3.6](http://opensource.adobe.com/wiki/display/flexsdk/Download+Flex+3) and [Java EE](http://www.oracle.com/technetwork/java/javaee/downloads/index.html).  However, we recommend the following setup: http://bugs.oicweave.org/projects/weave/wiki/Development_environment_setup

To build the projects on the command line, use the **WeaveClient/buildall.xml** and **WeaveServices/build.xml** Ant scripts.

See install-linux.md for detailed linux install instructions.
