Weave: Web-based Analysis and Visualization Environment

Project website: http://ivpr.github.com/Weave/

Issue Tracker: http://129.63.8.219/bugzilla

The binaries are included in [weave.zip](http://github.com/IVPR/Weave/raw/master/weave.zip)


Projects in this repository:

 * WeaveAPI: MPL tri-license, ActionScript interface classes
 * WeaveCore: GPLv3 license, core sessioning framework
 * WeaveData: GPLv3 license, columns related to loading data and other non-UI features.
 * WeaveUI: GPLv3 license, user interface classes
 * WeaveClient: GPLv3 license, Flex client application for visualization environment
 * WeaveAdmin: GPLv3 license, Flex application for admin activities
 * WeaveServices: GPLv3 license, back-end Java webapp for Admin and Data server features

The bare minimum you need to build Weave is [Flex 3.5](http://fpdownload.adobe.com/pub/flex/sdk/builds/flex3/flex_sdk_3.5.0.12683_mpl.zip) and [Java EE](http://www.oracle.com/technetwork/java/javaee/downloads/index.html).  However, we recommend the following setup: https://github.com/IVPR/Weave/wiki/Development-Environment-Setup

To build the projects on the command line, use the **WeaveClient/buildall.xml** and **WeaveServices/build.xml** Ant scripts.

See README-linux.md for more detailed Linux build instructions.
