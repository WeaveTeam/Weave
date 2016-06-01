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
	import weavejs.api.net.IWeaveEntityManagementService;
	import weavejs.api.net.beans.Entity;
	import weavejs.api.net.beans.EntityHierarchyInfo;
	import weavejs.api.net.beans.EntityMetadata;
	import weavejs.core.CallbackCollection;
	import weavejs.core.LinkableBoolean;
	import weavejs.net.beans.ConnectionInfo;
	import weavejs.net.beans.DatabaseConfigInfo;
	import weavejs.net.beans.WeaveFileInfo;
	import weavejs.util.JS;
	import weavejs.util.JSByteArray;
	import weavejs.util.StandardLib;
	import weavejs.util.WeavePromise;
	
	/**
	 * The functions in this class correspond directly to Weave servlet functions written in Java.
	 * This object uses a queue to guarantee that asynchronous servlet calls will execute in the order they are requested.
	 * @author adufilie
	 * @see WeaveServices/src/weave/servlets/AdminService.java
	 * @see WeaveServices/src/weave/servlets/DataService.java
	 */	
	public class WeaveAdminService implements IWeaveEntityManagementService
	{
		public static const WEAVE_AUTHENTICATION_EXCEPTION:String = 'WeaveAuthenticationException';
		
		public static const messageLog:Array = new Array();
		public static const messageLogCallbacks:CallbackCollection = new CallbackCollection();
		public static function messageDisplay(messageTitle:String, message:String, showPopup:Boolean):void
		{
			// for errors, both a popupbox and addition in the Log takes place
			// for successes, only addition in Log takes place
			if (showPopup)
				JS.global.alert(message,messageTitle);

			// always add the message to the log
			if (messageTitle == null)
				messageLog.push(message);
			else
				messageLog.push(messageTitle + ": " + message);
			
			messageLogCallbacks.triggerCallbacks();
		}
		public static function clearMessageLog():void
		{
			messageLog.length = 0;
			messageLogCallbacks.triggerCallbacks();
		}
		
		/**
		 * @param url The URL pointing to where a WeaveServices.war has been deployed.  Example: http://example.com/WeaveServices
		 */		
		public function WeaveAdminService(url:String)
		{
			adminService = Weave.linkableChild(this, new AMF3Servlet(url + "/AdminService", false));
			dataService = Weave.linkableChild(this, new AMF3Servlet(url + "/DataService", false));
			
			resetQueue();
			initializeAdminService();
		}

		private var map_method_name:Object = new JS.Map(); // method->string

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
		
		private function resetQueue():void
		{
			if (queue)
				Weave.dispose(queue);
			queue = Weave.linkableChild(this, new AsyncInvocationQueue(!initialized)); // paused if not initialized
		}
		
		private var queue:AsyncInvocationQueue;
		private var adminService:AMF3Servlet;
		private var dataService:AMF3Servlet;
		private var methodHooks:Object = {}; // methodName -> Array (of MethodHook)
        /*Bindable*/ public var initialized:Boolean = false;
		/*Bindable*/ public var migrationProgress:String = '';
		
		public function get entityServiceInitialized():Boolean
		{
			return authenticated.value;
		}
		
		//TODO - move hooks from Admin.as to here, and automatically set these user/pass/authenticated settings
		public const authenticated:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(false));
		/*Bindable*/ public var user:String = '';
		/*Bindable*/ public var pass:String = '';
		
		//////////////////////////////
		// Initialization
		
		public function initializeAdminService():WeavePromise/*/<void>/*/
		{
			var req:URLRequest = new URLRequest(adminService.servletURL);

			return invokeAdmin(initializeAdminService, arguments, false).then(
				initializeAdminServiceComplete,
				initializeAdminServiceError
			);
		}

		private function initializeAdminServiceComplete(result:*):void
		{
			initialized = true;
			queue.begin();
		}
		private function initializeAdminServiceError(error:*):void
		{
			//fixErrorMessage(error);
			messageDisplay(null, error, true);
		}
		
		/**
		 * @param method A pointer to a function of this WeaveAdminService.
		 * @param captureHandler Receives the parameters of the RPC call with the 'this' pointer set to the WeavePromise object.
		 * @param resultHandler A ResultEvent handler:  function(event:ResultEvent, parameters:Array = null):void
		 * @param faultHandler A FaultEvent handler:  function(event:FaultEvent, parameters:Array = null):void
		 */
		public function addHook(method:Function, captureHandler:Function, resultHandler:Function, faultHandler:Function = null):void
		{
			var methodName:String = getMethodName(method);
			if (!methodName)
				throw new Error("method must be a member of WeaveAdminService");
			var hooks:Array = methodHooks[methodName];
			if (!hooks)
				methodHooks[methodName] = hooks = [];
			var hook:MethodHook = new MethodHook();
			hook.captureHandler = captureHandler;
			hook.resultHandler = resultHandler;
			hook.faultHandler = faultHandler;
			hooks.push(hook);
		}
		
		private function hookCaptureHandler(methodName:String, methodParams:Array, query:WeavePromise/*/<any>/*/):void
		{
			for each (var hook:MethodHook in methodHooks[methodName])
			{
				if (hook.captureHandler == null)
					continue;
				var args:Array = methodParams ? methodParams.concat() : [];
				args.length = hook.captureHandler.length;
				hook.captureHandler.apply(query, args);
			}
		}
		
		/**
		 * This gets called automatically for each ResultEvent from an RPC.
		 * @param method The WeaveAdminService function which corresponds to the RPC.
		 */
		private function hookHandler(methodName:String, methodParams:Array, result:*):void
		{
			var handler:Function;
			for each (var hook:MethodHook in methodHooks[methodName])
			{
				if (!(result is Error))
					handler = hook.resultHandler;
				else
					handler = hook.faultHandler;
				if (handler == null)
					continue;
				
				var args:Array = [result, methodParams];
				args.length = handler.length;
				handler.apply(null, args);
			}
		}
		
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param method A WeaveAdminService class member function.
		 * @param parameters Parameters for the servlet method.
		 * @param queued If true, the request will be put into the queue so only one request is made at a time.
		 * @return The DelayedAsyncInvocation object representing the servlet method invocation.
		 */		
		private function invokeAdmin(method:Function, parameters:Array, queued:Boolean = true, returnType:Class = null):WeavePromise/*/<any>/*/
		{
			var methodName:String = getMethodName(method);
			if (!methodName)
				throw new Error("method must be a member of WeaveAdminService");
			return generateQuery(adminService, methodName, JS.global.Array.from(parameters), queued, returnType);
		}
		
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param methodName The name of a Weave DataService servlet method.
		 * @param parameters Parameters for the servlet method.
		 * @param queued If true, the request will be put into the queue so only one request is made at a time.
		 * @return The DelayedAsyncInvocation object representing the servlet method invocation.
		 */		
		private function invokeDataService(method:Function, parameters:Array, queued:Boolean = true, returnType:Class = null):WeavePromise/*/<any>/*/
		{
			var methodName:String = getMethodName(method);
			if (!methodName)
				throw new Error("method must be a member of WeaveAdminService");
			return generateQuery(dataService, methodName, JS.global.Array.from(parameters), queued, returnType);
		}
		
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param service The servlet.
		 * @param methodName The name of a servlet method.
		 * @param parameters Parameters for the servlet method.
		 * @param returnType The type of object which the result should be cast to.
		 * @return The WeavePromise<any> object representing the servlet method invocation.
		 */		
		private function generateQuery(service:AMF3Servlet, methodName:String, parameters:Array, queued:Boolean, returnType:Class):WeavePromise/*/<any>/*/
		{
			var query:WeavePromise/*/<any>/*/ = service.invokeAsyncMethod(methodName, parameters);
			var castedQuery:WeavePromise;
			query.then(null, interceptFault.bind(this, query)); /* query? */
			
			if (queued)
				queue.addToQueue(query, service);
			
			hookCaptureHandler(methodName, parameters, query);

			if ([null, Array, String, Number].indexOf(returnType) < 0)
			{
				castedQuery = query.then(WeaveDataServlet.castResult.bind(this, returnType));
			}
			else
			{
				castedQuery = query;
			}

			castedQuery.then(hookHandler.bind(this, methodName, parameters));
			
			if (!queued)
				service.invokeDeferred(query);
			
			return castedQuery;
		}
		
		// this function displays a String response from a server in an Alert box.
		private function alertResult(result:*, token:Object = null):void
		{
			messageDisplay(null,result,false);
		}
		
		private static const PREVENT_FAULT_ALERT:Object = new JS.WeakMap();

		/**
		 * Prevents the default error display if a fault occurs.
		 * @param query A WeavePromise<any> that was generated by this service.
		 */		
		public function hideFaultMessage(query:WeavePromise/*/<any>/*/):void
		{
			PREVENT_FAULT_ALERT.set(query, true);
		}
		
		private function interceptFault(query:WeavePromise/*/<any>/*/, error:*):void
		{
			// if user has been signed out, clear the queue immediately
			JS.error(error);
			if (error == WEAVE_AUTHENTICATION_EXCEPTION && authenticated.value)
			{
				resetQueue();
				authenticated.value = false;
				user = '';
				pass = '';
			}
		}
		
		// this function displays an error message from a FaultEvent in an Alert box.
		private function alertFault(methodName:String, methodParams:Array, query:WeavePromise/*/<any>/*/, error:*):void
		{
			//fixErrorMessage(event.fault);
			if (PREVENT_FAULT_ALERT.has(query))
			{
				PREVENT_FAULT_ALERT['delete'](query);
				return;
			}
			
			var paramDebugStr:String = '';
			
			if (methodParams is Array && methodParams.length > 0)
				paramDebugStr = methodParams.map(function(p:Object, i:int, a:Array):String { return Weave.stringify(p); }).join(', ');
			else
				paramDebugStr += Weave.stringify(methodParams);
			
			JS.error(StandardLib.substitute(
					"Received error on {0}({1}):\n\t{2}",
					methodName,
					paramDebugStr,
					error
				));
			
			//Alert.show(event.fault.faultString, event.fault.name);
			var msg:String = error.toString();
			if (msg == "ioError")
				msg = "Received no response from the servlet.\n"
					+ "Has the WAR file been deployed correctly?\n"
					+ "Expected servlet URL: "+ adminService.servletURL;
			messageDisplay(error, msg, true);
		}
		
		public function getVersion():WeavePromise/*/<string>/*/
		{
			return invokeAdmin(getVersion, arguments);
		}

		public function checkDatabaseConfigExists():WeavePromise/*/<boolean>/*/
		{
			return invokeAdmin(checkDatabaseConfigExists, arguments);
		}

		public function getAuthenticatedUser():WeavePromise/*/<string>/*/
		{
			return invokeAdmin(whoAmI, arguments);
		}
		
		public function authenticate(user:String, pass:String):WeavePromise/*/<boolean>/*/
		{
			return invokeAdmin(authenticate, arguments);
		}
		
		public function keepAlive():WeavePromise/*/<void>/*/
		{
			return invokeAdmin(keepAlive, arguments);
		}

		//////////////////////////////
		// Weave client config files

		public function getWeaveFileNames(showAllFiles:Boolean):WeavePromise/*/<string[]>/*/
		{
			return invokeAdmin(getWeaveFileNames, arguments);
		}

		public function saveWeaveFile(fileContent:JSByteArray, fileName:String, overwriteFile:Boolean):WeavePromise/*/<string>/*/
		{
			var query:WeavePromise/*/<any>/*/ = invokeAdmin(saveWeaveFile, arguments);
			return query;
		}

		public function removeWeaveFile(fileName:String):WeavePromise/*/<string>/*/
		{
			var query:WeavePromise/*/<any>/*/ = invokeAdmin(removeWeaveFile, arguments);
			return query;
		}

		public function getWeaveFileInfo(fileName:String):WeavePromise/*/<WeaveFileInfo>/*/
		{
			return invokeAdmin(getWeaveFileInfo, arguments, false, WeaveFileInfo); // bypass queue
		}
		
		//////////////////////////////
		// ConnectionInfo management
		
		public function getConnectionNames():WeavePromise/*/<string[]>/*/
		{
			return invokeAdmin(getConnectionNames, arguments);
		}
		public function getConnectionInfo(userToGet:String):WeavePromise/*/<ConnectionInfo>/*/
		{
			return invokeAdmin(getConnectionInfo, arguments, true, ConnectionInfo);
		}
		public function saveConnectionInfo(info:ConnectionInfo, configOverwrite:Boolean):WeavePromise/*/<string>/*/
		{
			var query:WeavePromise/*/<any>/*/ = invokeAdmin(
				saveConnectionInfo,
				[info.name, info.pass, info.folderName, info.is_superuser, info.connectString, configOverwrite]
			);
		    return query;
		}
		public function removeConnectionInfo(connectionNameToRemove:String):WeavePromise/*/<string>/*/
		{
			var query:WeavePromise/*/<any>/*/ = invokeAdmin(removeConnectionInfo, arguments);
			return query;
		}
		
		//////////////////////////////////
		// DatabaseConfigInfo management
		
		public function getDatabaseConfigInfo():WeavePromise/*/<DatabaseConfigInfo>/*/
		{
			return invokeAdmin(getDatabaseConfigInfo, arguments, true, DatabaseConfigInfo);
		}

		public function setDatabaseConfigInfo(connectionName:String, password:String, schema:String, idFields:Array):WeavePromise/*/<string>/*/
		{
			var query:WeavePromise/*/<any>/*/ = invokeAdmin(setDatabaseConfigInfo, arguments);
			return query;
		}

		//////////////////////////
		// DataEntity management
		
		public function newEntity(metadata:EntityMetadata, parentId:int, insertAtIndex:int):WeavePromise/*/<number>/*/
		{
			return invokeAdmin(newEntity, arguments);
		}

		public function updateEntity(entityId:int, diff:EntityMetadata):WeavePromise/*/<void>/*/
		{
			return invokeAdmin(updateEntity, arguments);
		}

		public function removeEntities(entityIds:Array):WeavePromise/*/<number[]>/*/
		{
			return invokeAdmin(removeEntities, arguments);
		}

		public function addChild(parentId:int, childId:int, insertAtIndex:int):WeavePromise/*/<number[]>/*/
		{
			return invokeAdmin(addChild, arguments);
		}

		public function removeChild(parentId:int, childId:int):WeavePromise/*/<void>/*/
		{
			return invokeAdmin(removeChild, arguments);
		}

		public function getHierarchyInfo(publicMetadata:Object):WeavePromise/*/<EntityHierarchyInfo[]>/*/
		{
			return invokeAdmin(getHierarchyInfo, arguments, true, EntityHierarchyInfo);
		}

		public function getEntities(entityIds:Array):WeavePromise/*/<Entity[]>/*/
		{
			return invokeAdmin(getEntities, arguments, true, Entity);
		}

		public function findEntityIds(publicMetadata:Object, wildcardFields:Array):WeavePromise/*/<number[]>/*/
		{
			return invokeAdmin(findEntityIds, arguments);
		}

		public function findPublicFieldValues(fieldName:String, valueSearch:String):WeavePromise/*/<string[]>/*/
		{
			return invokeAdmin(findPublicFieldValues, arguments);
		}
		
		///////////////////////
		// SQL info retrieval

		public function getSQLSchemaNames():WeavePromise/*/<string[]>/*/
		{
			return invokeAdmin(getSQLSchemaNames, arguments, false);
		}

		public function getSQLTableNames(schemaName:String):WeavePromise/*/<string[]>/*/
		{
			return invokeAdmin(getSQLTableNames, arguments, false);
		}

		public function getSQLColumnNames(schemaName:String, tableName:String):WeavePromise/*/<string[]>/*/
		{
			return invokeAdmin(getSQLColumnNames, arguments, false);
		}

		/////////////////
		// File uploads
		
		public function uploadFile(fileName:String, bytes:/*/Uint8Array/*/Array):WeavePromise/*/<void>/*/
		{
			// queue up requests for uploading chunks at a time, then return the token of the last chunk
			
			var MB:int = ( 1024 * 1024 );
			var maxChunkSize:int = 20 * MB;
			var chunkSize:int = (bytes.length > (5*MB)) ? Math.min((bytes.length / 10 ), maxChunkSize) : ( MB );
			var offset:int = 0;

			var promise:WeavePromise/*/<any>/*/;
			do
			{
				var chunkLength:int = Math.min(chunkSize, bytes.length - offset);
				var chunk:Object = bytes.subarray(offset, offset+chunkLength);

				offset += chunkLength;
				
				promise = invokeAdmin(uploadFile, [fileName, chunk, offset > 0], true); // queued -- important!
			}
			while (offset < bytes.length);
			
			return promise;
		}

		public function getUploadedCSVFiles():WeavePromise/*/<WeaveFileInfo[]>/*/
		{
			return invokeAdmin(getUploadedCSVFiles, arguments, false, WeaveFileInfo);
		}

		public function getUploadedSHPFiles():WeavePromise/*/<WeaveFileInfo[]>/*/
		{
			return invokeAdmin(getUploadedSHPFiles, arguments, false, WeaveFileInfo);
		}

		public function getCSVColumnNames(csvFiles:String):WeavePromise/*/<string[]>/*/
		{
			return invokeAdmin(getCSVColumnNames, arguments);
		}

		public function getDBFColumnNames(dbfFileNames:Array):WeavePromise/*/<string[]>/*/
		{
		    return invokeAdmin(getDBFColumnNames, arguments);
		}
		
		/////////////////////////////////
		// Key column uniqueness checks
		
		public function checkKeyColumnsForSQLImport(schemaName:String, tableName:String, keyColumns:Array):WeavePromise/*/<void>/*/
		{
			return invokeAdmin(checkKeyColumnsForSQLImport, arguments);
		}

		public function checkKeyColumnsForCSVImport(csvFileName:String, keyColumns:Array):WeavePromise/*/<void>/*/
		{
			return invokeAdmin(checkKeyColumnsForCSVImport, arguments);
		}

		public function checkKeyColumnsForDBFImport(dbfFileNames:Array, keyColumns:Array):WeavePromise/*/<boolean>/*/
		{
			return invokeAdmin(checkKeyColumnsForDBFImport, arguments);
		}
		
		////////////////
		// Data import
		
		public function importCSV(
				csvFile:String, csvKeyColumn:String, csvSecondaryKeyColumn:String,
				sqlSchema:String, sqlTable:String, sqlOverwrite:Boolean, configDataTableName:String,
				configKeyType:String, nullValues:String,
				filterColumnNames:Array, configAppend:Boolean
			):WeavePromise/*/<number>/*/
		{
		    return invokeAdmin(importCSV, arguments);
		}
		public function importSQL(
				schemaName:String, tableName:String, keyColumnName:String,
				secondaryKeyColumnName:String, configDataTableName:String,
				keyType:String, filterColumns:Array, configAppend:Boolean
			):WeavePromise/*/<number>/*/
		{
		    return invokeAdmin(importSQL, arguments);
		}
		public function importSHP(
				configfileNameWithoutExtension:String, keyColumns:Array,
				sqlSchema:String, sqlTablePrefix:String, sqlOverwrite:Boolean, configTitle:String,
				configKeyType:String, configProjection:String, nullValues:String, importDBFAsDataTable:Boolean, configAppend:Boolean
			):WeavePromise/*/<number>/*/
		{
		    return invokeAdmin(importSHP, arguments);
		}
		
		public function importDBF(
				fileNameWithoutExtension:String, sqlSchema:String,
				sqlTableName:String, sqlOverwrite:Boolean, nullValues:String
			):WeavePromise/*/<void>/*/
		{
			return invokeAdmin(importDBF, arguments);
		}
		
		//////////////////////
		// SQL query testing
		
		public function testAllQueries(tableId:int):WeavePromise/*/<any[]>/*/
		{
			return invokeAdmin(testAllQueries, arguments, false);
		}
		
		//////////////////
		// Miscellaneous
		
		public function getKeyTypes():WeavePromise/*/<string[]>/*/
		{
			return invokeAdmin(getKeyTypes, arguments);
		}
		
		// this function is for verifying the local connection between Weave and the AdminConsole.
		public function ping():String { return "pong"; }
		
		//////////////////////////
		// DataService functions
		
		public function getAttributeColumn(metadata:Object):WeavePromise/*/<any>/*/
		{
			return invokeDataService(getAttributeColumn, arguments, false);
		}
	}
}

internal class MethodHook
{
	public var captureHandler:Function;
	public var resultHandler:Function;
	public var faultHandler:Function;
}
