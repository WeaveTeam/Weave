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
	import avmplus.DescribeType;
	
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.rpc.AsyncToken;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.utils.HierarchyUtils;
	
	/**
	 * This is a wrapper class for making asynchronous calls to a Weave data servlet.
	 * 
	 * @author adufilie
	 */
	public class WeaveDataServlet implements ILinkableObject
	{
		protected var servlet:AMF3Servlet;
		private var propertyNameLookup:Dictionary = new Dictionary(); // Function -> String

		public function WeaveDataServlet(url:String)
		{
			servlet = new AMF3Servlet(url);
			registerLinkableChild(this, servlet);
			
			var info:* = describeTypeJSON(this, DescribeType.METHOD_FLAGS);
			for each (var item:Object in info.traits.methods)
			{
				var func:Function = this[item.name] as Function;
				if (func != null)
					propertyNameLookup[func] = item.name;
			}
		}
		
		////////////////////
		// Helper functions
		
		/**
		 * avmplus.describeTypeJSON(o:*, flags:uint):Object
		 */		
		private const describeTypeJSON:Function = DescribeType.getJSONFunction();
		
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param method A WeaveAdminService class member function or a String.
		 * @param parameters Parameters for the servlet method.
		 * @param queued If true, the request will be put into the queue so only one request is made at a time.
		 * @return The DelayedAsyncInvocation object representing the servlet method invocation.
		 */		
		private function invoke(method:Object, parameters:Array):AsyncToken
		{
			var methodName:String;
			if (method is Function)
				methodName = propertyNameLookup[method] as String;
			else
				methodName = method as String;
			
			if (!methodName)
				throw new Error("method must be a member of " + getQualifiedClassName(this));
			
			return servlet.invokeAsyncMethod(methodName, parameters);
		}
		
		////////////////////
		// DataEntity info
		
		public function getDataTableList():AsyncToken // returns DataEntityTableInfo[]
		{
			return invoke(getDataTableList, arguments);
		}
		
		public function getEntityChildIds(parentId:int):AsyncToken // returns int[]
		{
			return invoke(getEntityChildIds, arguments);
		}
		
		public function getEntityIdsByMetadata(publicMetadata:Object, entityType:int):AsyncToken // returns int[]
		{
			return invoke(getEntityIdsByMetadata, arguments);
		}
		
		public function getEntitiesById(ids:Array):AsyncToken // returns DataEntity[]
		{
			return invoke(getEntitiesById, arguments);
		}
		
		
		public function getParents(id:int):AsyncToken // returns DataEntity[]
		{
			return invoke(getParents, arguments);
		}
		
		////////////////////////////////////
		// string and numeric data columns
		
		public function getColumn(columnId:int, minParam:Number, maxParam:Number, sqlParams:Array):AsyncToken // returns AttributeColumnData
		{
			return invoke(getColumn, arguments);
		}
		
		/////////////////////
		// Geometry columns
		
		public function getGeometryStreamTileDescriptors(columnId:int):AsyncToken // returns GeometryStreamMetadata
		{
			return invoke(getGeometryStreamTileDescriptors, arguments);
		}
		public function getGeometryStreamMetadataTiles(columnId:int, tileIDs:Array):AsyncToken // returns byte[]
		{
			return invoke(getGeometryStreamMetadataTiles, arguments);
		}
		public function getGeometryStreamGeometryTiles(columnId:int, tileIDs:Array):AsyncToken // returns byte[]
		{
			return invoke(getGeometryStreamGeometryTiles, arguments);
		}
		
		public function createTileService(columnId:int):IWeaveGeometryTileService
		{
			var tileService:IWeaveGeometryTileService = new WeaveGeometryTileServlet(this, columnId);
			
			// when we dispose of this servlet, we also want to dispose of the spawned tile servlet
			registerDisposableChild(this, tileService);
			
			return tileService;
		}
		
		//////////////
		// Row query
		
		public function getRows(keys:Array):AsyncToken // returns WeaveRecordList
		{
			var keysArray:Array = [];
			for each( var key:IQualifiedKey in keys)
			{
				keysArray.push(key.localName);
			}
			var keytype:String = (keys[0] as IQualifiedKey).keyType;
			return invoke(getRows,[keytype,keysArray]);
		}
		
		////////////////////////////
		// backwards compatibility
		
		[Deprecated] public function getColumnFromMetadata(metadata:Object):AsyncToken // returns AttributeColumnData
		{
			return invoke(getColumnFromMetadata, arguments);
		}
	}
}


import mx.rpc.AsyncToken;

import weave.api.WeaveAPI;
import weave.api.services.IWeaveGeometryTileService;
import weave.services.WeaveDataServlet;

/**
 * This is an implementation of IWeaveGeometryTileService that uses a WeaveDataServlet as the tile source.
 * 
 * @author adufilie
 */
internal class WeaveGeometryTileServlet implements IWeaveGeometryTileService
{
	public function WeaveGeometryTileServlet(service:WeaveDataServlet, columnId:int)
	{
		_service = service;
		_columnId = columnId;
	}
	
	private var _service:WeaveDataServlet;
	private var _columnId:int;
	
	public function getMetadataTiles(tileIDs:Array):AsyncToken
	{
		var token:AsyncToken = _service.getGeometryStreamMetadataTiles(_columnId, tileIDs);
		WeaveAPI.SessionManager.assignBusyTask(token, this);
		return token;
	}
	
	public function getGeometryTiles(tileIDs:Array):AsyncToken
	{
		var token:AsyncToken = _service.getGeometryStreamGeometryTiles(_columnId, tileIDs);
		WeaveAPI.SessionManager.assignBusyTask(token, this);
		return token;
	}
}
