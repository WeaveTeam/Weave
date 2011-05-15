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

package org.oicweave.services
{
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import mx.rpc.AsyncToken;
	import mx.utils.ObjectUtil;
	
	import org.oicweave.utils.HierarchyUtils;

	public class WFSServlet extends Servlet
	{
		public function WFSServlet(wfsURL:String, version:String="1.1.0")
		{
			super(wfsURL, "request", URLLoaderDataFormat.VARIABLES);

			this.version = version;
		}
		
		public var version:String;
		
		public function getCapabilties():AsyncToken
		{
			return invokeAsyncMethod("getCapabilities", {version: version});
		}
		
		public function describeFeatureType(layerName:String):AsyncToken
		{
			return invokeAsyncMethod("DescribeFeatureType", {version: version, typeName: layerName});
		}
		
		public function getFeature(layerName:String, propertyNames:Array = null):AsyncToken
		{
			var params:Object = {version: version, typeName: layerName};
			if(propertyNames != null && propertyNames.length != 0)
				params.propertyName = propertyNames.join(',');
			
			return invokeAsyncMethod("GetFeature", params);
		}
		
		public function getFilteredQueryResult(layerName:String, propertyNames:Array, filterQuery:String):AsyncToken
		{
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
