/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.services
{
	import flash.net.URLLoaderDataFormat;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.reportError;

	public class WFSServlet extends Servlet
	{
		public function WFSServlet(wfsURL:String, useURLsInGetCapabilities:Boolean, version:String="1.1.0")
		{
			super(wfsURL, "request", URLLoaderDataFormat.VARIABLES);

			this.version = version;
			this.url_getCapabilities = wfsURL;
			this.url_describeFeatureType = wfsURL;
			this.url_getFeature = wfsURL;
			
			if (useURLsInGetCapabilities)
				invokeLater = true;
		}
		
		public var version:String;
		
		private var url_getCapabilities:String;
		private var url_describeFeatureType:String;
		private var url_getFeature:String;
		
		private var delayedInvocations:Array = [];
		
		public function getCapabilties():AsyncToken
		{
			_getCapabilitiesCalled = true;
			
			var token:AsyncToken = invokeAsyncMethod("getCapabilities", {version: version});
			
			if (invokeLater)
			{
				addAsyncResponder(token, handleGetCapabilities, handleGetCapabilitiesFault);
				invokeNow(token); // invoke getCapabilities immediately
			}
			
			return token;
		}
		
		private var _getCapabilitiesCalled:Boolean = false;
		
		private function handleGetCapabilities(event:ResultEvent, token:Object=null):void
		{
			var owsNS:String = 'http://www.opengis.net/ows';
			var xlinkNS:String = 'http://www.w3.org/1999/xlink';
			var xml:XML;
			try
			{
				xml = XML(event.result);
				var operations:XMLList = xml.descendants(new QName(owsNS, 'Operation'));
				var owsGet:QName = new QName(owsNS, 'Get');
				var xlinkHref:QName = new QName(xlinkNS, 'href');
				url_describeFeatureType = operations.(@name == "DescribeFeatureType").descendants(owsGet).attribute(xlinkHref);
				url_getFeature = operations.(@name == "GetFeature").descendants(owsGet).attribute(xlinkHref);
			}
			catch (e:Error)
			{
				reportError("Unable to parse GetCapabilities response.");
				
				if (xml)
					trace(xml.toXMLString());
			}
			
			invokeLater = false; // resume all delayed url requests 
		}
		private function handleGetCapabilitiesFault(..._):void
		{
			// assume the urls for these methods are the same as the one that just failed
			invokeLater = false; // resume all delayed url requests
		}
		
		override protected function getServletURLForMethod(methodName:String):String
		{
			if (methodName == 'GetCapabilities')
				return url_getCapabilities;
			if (methodName == 'GetFeature')
				return url_getFeature;
			if (methodName == 'DescribeFeatureType')
				return url_describeFeatureType;
			return _servletURL;
		}
		
		public function describeFeatureType(layerName:String):AsyncToken
		{
			if (!_getCapabilitiesCalled)
				getCapabilties();
				
			return invokeAsyncMethod("DescribeFeatureType", {version: version, typeName: layerName});
		}
		
		public function getFeature(layerName:String, propertyNames:Array = null):AsyncToken
		{
			if (!_getCapabilitiesCalled)
				getCapabilties();
			
			var params:Object = {version: version, typeName: layerName};
			if (propertyNames != null && propertyNames.length != 0)
				params.propertyName = propertyNames.join(',');
			
			return invokeAsyncMethod("GetFeature", params);
		}
		
		public function getFilteredQueryResult(layerName:String, propertyNames:Array, filterQuery:String):AsyncToken
		{
			if (!_getCapabilitiesCalled)
				getCapabilties();
			
			var params:Object = {version: version, typeName: layerName, filter: filterQuery};
			if(propertyNames != null && propertyNames.length != 0)
				params.propertyName = propertyNames.join(',');
			
			return invokeAsyncMethod("GetFeature", params);
		}
		
/*		public function getAttributeColumn(pathInHierarchy:XML):AsyncToken
		{
			var node:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			
			var params:Object = new Object();
			for each (var attr:String in ['dataTable', 'name', 'year', 'min', 'max'])
			{
				var value:String = node.attribute(attr);
				if (value != '')
					params[attr] = value;
			}
			
			return invokeAsyncMethod("getAttributeColumn", params);
		}
*/		
	}
}

internal class DelayedInvocation
{
	public function DelayedInvocation(func:Function, args:Array)
	{
		this.func = func;
		this.args = args;
	}
	
	private var func:Function;
	private var args:Array;
	
	public function invoke():void
	{
		func.apply(null, args);
	}
}
