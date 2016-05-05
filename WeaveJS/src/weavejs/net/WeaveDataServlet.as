/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weavejs.net
{
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.net.IWeaveEntityService;
	import weavejs.api.net.IWeaveGeometryTileService;
	import weavejs.api.net.beans.Entity;
	import weavejs.api.net.beans.EntityHierarchyInfo;
	import weavejs.net.beans.AttributeColumnData;
	import weavejs.net.beans.GeometryStreamMetadata;
	import weavejs.net.beans.TableData;
	import weavejs.util.JS;
	import weavejs.util.WeavePromise;
	
	/**
	 * This is a wrapper class for making asynchronous calls to a Weave data servlet.
	 * 
	 * @author adufilie
	 */
	public class WeaveDataServlet implements IWeaveEntityService
	{
		public static const DEFAULT_URL:String = '/WeaveServices/DataService';
		public static const WEAVE_AUTHENTICATION_EXCEPTION:String = 'WeaveAuthenticationException';
		private static const AUTHENTICATED_USER:String = 'authenticatedUser';
		
		private var map_method_name:Object = new JS.Map(); // Function -> String
		protected var servlet:AMF3Servlet;
		protected var _serverInfo:Object = null;

		public function WeaveDataServlet(url:String = null)
		{
			servlet = Weave.linkableChild(this, new AMF3Servlet(url || DEFAULT_URL, false));
		}
		
		////////////////////
		// Helper functions

		private function getMethodName(method:Object):String
		{
			if (method is String)
				return method as String;
			
			if (!map_method_name.has(method))
			{
				for each (var name:String in JS.getPropertyNames(this, true))
				{
					if (this[name] === method)
					{
						map_method_name.set(method, name);
						return name;
					}
				}
			}
			return map_method_name.get(method);
		}
		
		/**
		 * This function will generate a AsyncToken representing a servlet method invocation.
		 * @param method A WeaveAdminService class member function or a String.
		 * @param parameters Parameters for the servlet method.
		 * @param returnType_or_castFunction
		 *     Either the type of object (Class) returned by the service or a Function that converts an Object to the appropriate type.
		 *     If the service returns an Array of objects, each object in the Array will be cast to this type.
		 *     The object(s) returned by the service will be cast to this type by copying the public properties of the objects.
		 *     It is unnecessary to specify this parameter if the return type is a primitive value.
		 * @return The AsyncToken object representing the servlet method invocation.
		 */		
		private function invoke(method:Object, parameters:Array, returnType_or_castFunction:Object = null):WeavePromise/*/<any>/*/
		{
			parameters = JS.toArray(parameters) || parameters;
			var methodName:String = getMethodName(method);
			if (!methodName)
				throw new Error("method must be a member of " + Weave.className(this));
			
			var promise:WeavePromise = servlet.invokeAsyncMethod(methodName, parameters);
			var promiseThen:WeavePromise = promise;
			if (!_authenticationRequired)
				servlet.invokeDeferred(promise);
			if (returnType_or_castFunction)
			{
				if (!(returnType_or_castFunction is Function || JS.isClass(returnType_or_castFunction)))
					throw new Error("returnType_or_castFunction parameter must either be a Class or a Function");
				if ([Array, String, Number].indexOf(returnType_or_castFunction) < 0) // skip these primitive casts
					promiseThen = promise.then(castResult.bind(this, returnType_or_castFunction), function(error:*):* {
						if (error.code == WEAVE_AUTHENTICATION_EXCEPTION)
						{
							_authenticationRequired = true;
							_promisesPendingAuthentication.push(promise);
						}
						else
							JS.error(error);
					});
			}
			return promiseThen;
		}
		
		public static function castResult(cast:Object, originalResult:Object):Object
		{
			var results:Array = originalResult as Array || [originalResult];
			for (var i:int = 0; i < results.length; i++)
			{
				if (JS.isClass(cast))
				{
					var resultItem:Object = results[i];
					if (resultItem === null || resultItem is JS.asClass(cast))
						continue;
					var newResult:Object = new cast();
					for (var key:String in resultItem)
						newResult[key] = resultItem[key];
					results[i] = newResult;
				}
				else
				{
					results[i] = cast(results[i])
				}
			}
			return originalResult === results ? results : results[0];
		}
		
		//////////////////
		// Authentication
		
		private var _authenticationRequired:Boolean = false;
		private var _user:String = null;
		private var _pass:String = null;
		private var _promisesPendingAuthentication:Array = [];
		
		/**
		 * Check this to determine if authenticate() may be necessary.
		 * @return true if authenticate() may be necessary.
		 */
		public function get authenticationSupported():Boolean
		{
			var info:Object = getServerInfo();
			return info && info['hasDirectoryService'];
		}
		
		/**
		 * Check this to determine if authenticate() must be called.
		 * @return true if authenticate() should be called.
		 */
		public function get authenticationRequired():Boolean
		{
			return _authenticationRequired && !_user && !_pass;
		}
		
		public function get authenticatedUser():String
		{
			var info:Object = getServerInfo();
			return info ? info[AUTHENTICATED_USER] : null;
		}
		
		/**
		 * Authenticates with the server.
		 * @param user
		 * @param pass
		 */
		public function authenticate(user:String, pass:String):void
		{
			if (user && pass)
			{
				_user = user;
				_pass = pass;
				var promise:WeavePromise = invoke(authenticate, arguments);
				promise.then(handleAuthenticateResult, handleAuthenticateFault);
				// check if we have to invoke manually
				if (_authenticationRequired)
					servlet.invokeDeferred(promise);
			}
			else
			{
				_user = null;
				_pass = null;
			}
		}
		private function handleAuthenticateResult(_:*):void
		{
			while (_promisesPendingAuthentication.length)
				servlet.invokeDeferred(_promisesPendingAuthentication.shift() as WeavePromise);
			getServerInfo()[AUTHENTICATED_USER] = _user;
		}
		private function handleAuthenticateFault(_:*):void
		{
			_user = null;
			_pass = null;
		}
		
		////////////////
		// Server info
		
		public function getServerInfo():Object
		{
			if (!_serverInfo)
			{
				// setting _serverInfo to non-object until promise is resolved
				_serverInfo = true;
				invoke(getServerInfo, arguments).then(
					function(result:Object):void
					{
						_serverInfo = result || {};
					},
					function(error:Object):void
					{
						_serverInfo = {"error": error};
					}
				);
			}
			// return null until promise is resolved
			return typeof _serverInfo === 'object' ? _serverInfo : null;
		}
		
		////////////////////
		// DataEntity info
		
		public function get entityServiceInitialized():Boolean
		{
			return getServerInfo() != null;
		}
		
		public function getHierarchyInfo(publicMetadata:Object):WeavePromise/*/<EntityHierarchyInfo[]>/*/
		{
			return invoke(getHierarchyInfo, arguments, EntityHierarchyInfo);
		}
		
		public function getEntities(ids:Array):WeavePromise/*/<Entity[]>/*/
		{
			return invoke(getEntities, arguments, Entity);
		}
		
		public function findEntityIds(publicMetadata:Object, wildcardFields:Array):WeavePromise/*/<number[]>/*/
		{
			return invoke(findEntityIds, arguments);
		}
		
		public function findPublicFieldValues(fieldName:String, valueSearch:String):WeavePromise/*/<string[]>/*/
		{
			return invoke(findPublicFieldValues, arguments);
		}
		
		////////////////////////////////////
		// string and numeric data columns
		
		public function getColumn(columnId:Object, minParam:Number, maxParam:Number, sqlParams:Array):WeavePromise/*/<AttributeColumnData>/*/
		{
			return invoke(getColumn, arguments, AttributeColumnData);
		}
		
		public function getTable(id:int, sqlParams:Array):WeavePromise/*/<TableData>/*/
		{
			return invoke(getTable, arguments, TableData);
		}
		
		/////////////////////
		// Geometry columns
		
		public function getGeometryStreamTileDescriptors(columnId:int):WeavePromise/*/<GeometryStreamMetadata>/*/
		{
			return invoke(getGeometryStreamTileDescriptors, arguments, GeometryStreamMetadata);
		}
		public function getGeometryStreamMetadataTiles(columnId:int, tileIDs:Array):WeavePromise/*/<weavejs.util.JSByteArray>/*/
		{
			return invoke(getGeometryStreamMetadataTiles, arguments);
		}
		public function getGeometryStreamGeometryTiles(columnId:int, tileIDs:Array):WeavePromise/*/<weavejs.util.JSByteArray>/*/
		{
			return invoke(getGeometryStreamGeometryTiles, arguments);
		}
		
		public function createTileService(columnId:int):IWeaveGeometryTileService
		{
			var tileService:IWeaveGeometryTileService = new WeaveGeometryTileServlet(this, columnId);
			
			// when we dispose this servlet, we also want to dispose the spawned tile servlet
			Weave.disposableChild(this, tileService);
			
			return tileService;
		}
		
		//////////////
		// Row query
		
		public function getRows(keys:Array):WeavePromise/*/<{
				attributeColumnMetadata: {[key:string]:string}[],
				keyType: string,
				recordKeys: string[],
				recordData: any[][]
			}>/*/
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
		
		/**
		 * Deprecated. Use getColumn() instead.
		 */
		public function getColumnFromMetadata(metadata:Object):WeavePromise/*/<AttributeColumnData>/*/
		{
			return invoke(getColumnFromMetadata, arguments, AttributeColumnData);
		}
	}
}


import weavejs.WeaveAPI;
import weavejs.api.net.IWeaveGeometryTileService;
import weavejs.net.WeaveDataServlet;
import weavejs.util.WeavePromise;

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
	
	public function getMetadataTiles(tileIDs:Array):WeavePromise/*/<weavejs.util.JSByteArray>/*/
	{
		var token:WeavePromise = _service.getGeometryStreamMetadataTiles(_columnId, tileIDs);
		WeaveAPI.ProgressIndicator.addTask(token, this);
		return token;
	}
	
	public function getGeometryTiles(tileIDs:Array):WeavePromise/*/<weavejs.util.JSByteArray>/*/
	{
		var token:WeavePromise = _service.getGeometryStreamGeometryTiles(_columnId, tileIDs);
		WeaveAPI.ProgressIndicator.addTask(token, this);
		return token;
	}
}
