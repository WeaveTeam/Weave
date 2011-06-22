Weave: Web-based Analysis and Visualization Environment

Weave is a new open source web-based visualization platform enabling a range of users to explore, analyze, visualize and disseminate any data on-line from any location at any time. The new platform supports the development of visualizations for novices or advanced researchers and the ability to integrate, disseminate and visualize both data and indicators (economic, social and environmental) with various nested levels of geography (micro to macro).

Weave is the collaborative effort of the University of Massachusetts Lowell and the Open Indicators Consortium bringing together technical and academic experts, data providers and data users from initially nine partner agencies across eight US regions.

Project website: http://ivpr.github.com/Weave

Issue Tracker: http://bugs.oicweave.org

Nightly build: https://github.com/IVPR/Weave-Binaries/zipball/master

Developer documentation: http://ivpr.github.com/Weave/asdoc/

Components in this repository:

 * WeaveAPI: MPL tri-license, ActionScript interface classes
 * WeaveCore: GPLv3 license, core sessioning framework
 * WeaveData: GPLv3 license, columns related to loading data and other non-UI features.
 * WeaveUI: GPLv3 license, user interface classes
 * WeaveClient: GPLv3 license, Flex client application for visualization environment
 * WeaveAdmin: GPLv3 license, Flex application for admin activities
 * WeaveServices: GPLv3 license, back-end Java webapp for Admin and Data server features
 * GeometryStreamConverter: GPLv3 license, Java library for converting geometries into a streaming format

The bare minimum you need to build Weave is [Flex 3.5](http://fpdownload.adobe.com/pub/flex/sdk/builds/flex3/flex_sdk_3.5.0.12683_mpl.zip) and [Java EE](http://www.oracle.com/technetwork/java/javaee/downloads/index.html).  However, we recommend the following setup: https://github.com/IVPR/Weave/wiki/Development-Environment-Setup

To build the projects on the command line, use the **WeaveClient/buildall.xml** and **WeaveServices/build.xml** Ant scripts.

See INSTALL.md for more detailed instructions.
