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
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.StringUtil;
	
	import weave.core.CallbackCollection;
	import weave.services.beans.ConnectionInfo;
	import weave.services.beans.EntityMetadata;
	
	/**
	 * The functions in this class correspond directly to Weave servlet functions written in Java.
	 * This object uses a queue to guarantee that asynchronous servlet calls will execute in the order they are requested.
	 * @author adufilie
	 * @see WeaveServices/src/weave/servlets/AdminService.java
	 * @see WeaveServices/src/weave/servlets/DataService.java
	 */	
	public class WeaveAdminService
	{
		public static const messageLog:Array = new Array();
		public static const messageLogCallbacks:CallbackCollection = new CallbackCollection();
		public static function messageDisplay(messageTitle:String, message:String, showPopup:Boolean):void 
		{
			// for errors, both a popupbox and addition in the Log takes place
			// for successes, only addition in Log takes place
			if (showPopup)
				Alert.show(message,messageTitle);

			// always add the message to the log
			if (messageTitle == null)
				messageLog.push(message);
			else
				messageLog.push(messageTitle + ": " + message);
			
			messageLogCallbacks.triggerCallbacks();
		}
		
		/**
		 * @param url The URL pointing to where a WeaveServices.war has been deployed.  Example: http://example.com/WeaveServices
		 */		
		public function WeaveAdminService(url:String)
		{
			adminService = new AMF3Servlet(url + "/AdminService");
			dataService = new AMF3Servlet(url + "/DataService");
			queue = new AsyncInvocationQueue();
		}
		
		private var queue:AsyncInvocationQueue;
		private var adminService:AMF3Servlet;
		private var dataService:AMF3Servlet;
		
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param methodName The name of a Weave AdminService servlet method.
		 * @param parameters Parameters for the servlet method.
		 * @param queued If true, the request will be put into the queue so only one request is made at a time.
		 * @return The DelayedAsyncInvocation object representing the servlet method invocation.
		 */		
		private function invokeAdmin(methodName:String, parameters:Array, queued:Boolean = true):DelayedAsyncInvocation
		{
			if (queued)
				return generateQueryAndAddToQueue(adminService, methodName, parameters);
			return adminService.invokeAsyncMethod(methodName, parameters) as DelayedAsyncInvocation;
		}
		
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param methodName The name of a Weave AdminService servlet method.
		 * @param parameters Parameters for the servlet method.
		 * @param queued If true, the request will be put into the queue so only one request is made at a time.
		 * @return The DelayedAsyncInvocation object representing the servlet method invocation.
		 */		
		private function invokeAdminWithLogin(methodName:String, parameters:Array, queued:Boolean = true):DelayedAsyncInvocation
		{
			parameters.unshift(AdminInterface.instance.activeConnectionName, AdminInterface.instance.activePassword);
			return invokeAdmin(methodName, parameters, queued);
		}
			
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param methodName The name of a Weave DataService servlet method.
		 * @param parameters Parameters for the servlet method.
		 * @param queued If true, the request will be put into the queue so only one request is made at a time.
		 * @return The DelayedAsyncInvocation object representing the servlet method invocation.
		 */		
		private function invokeDataService(methodName:String, parameters:Array, queued:Boolean = true):DelayedAsyncInvocation
		{
			if (queued)
				return generateQueryAndAddToQueue(dataService, methodName, parameters);
			return dataService.invokeAsyncMethod(methodName, parameters) as DelayedAsyncInvocation;
		}
			
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param service The servlet.
		 * @param methodName The name of a servlet method.
		 * @param parameters Parameters for the servlet method.
		 * @param byteArray An optional byteArray to append to the end of the stream.
		 * @return The DelayedAsyncInvocation object representing the servlet method invocation.
		 */		
		private function generateQueryAndAddToQueue(service:AMF3Servlet, methodName:String, parameters:Array):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = new DelayedAsyncInvocation(service, methodName, parameters);
			// we want to use a queue so the admin functions will execute in the correct order.
			queue.addToQueue(query);
			// automatically display FaultEvent error messages as alert boxes
			addAsyncResponder(query, null, alertFault, query);
			return query;
		}
		
		// this function displays a String response from a server in an Alert box.
		private function alertResult(event:ResultEvent, token:Object = null):void
		{
			messageDisplay(null,String(event.result),false);
		}
		
		// this function displays an error message from a FaultEvent in an Alert box.
		public function alertFault(event:FaultEvent, token:Object = null):void
		{
			var query:AsyncToken = token as AsyncToken;
			
			var paramDebugStr:String = '';
			if (query.parameters.length > 0)
				paramDebugStr = '"' + query.parameters.join('", "') + '"';
			trace(StringUtil.substitute(
					"Received error on {0}({1}):\n\t{2}",
					query.methodName,
					paramDebugStr,
					event.fault.faultString
				));
			
			//Alert.show(event.fault.faultString, event.fault.name);
			var msg:String = event.fault.faultString;
			if (msg == "ioError")
				msg = "Received no response from the servlet.\nHas the WAR file been deployed correctly?\nExpected servlet URL: "+ adminService.servletURL;
			messageDisplay(event.fault.name, msg, true);
		}

		public function checkSQLConfigExists():AsyncToken
		{
			return invokeAdmin("checkSQLConfigExists", arguments);
		}
		
		public function authenticate():AsyncToken
		{
			return invokeAdminWithLogin("authenticate", arguments);
		}

		public function getConnectionInfo(connectionNameToGet:String):AsyncToken
		{
			return invokeAdminWithLogin("getConnectionInfo", arguments, false);
		}
		//public String setDatabaseConfigInfo(String connectionName, String password, String schema) 
		public function setDatabaseConfigInfo(connectionName:String, password:String, schema:String):AsyncToken
		{
			var query:AsyncToken = invokeAdmin("setDatabaseConfigInfo", arguments);
			addAsyncResponder(query, alertResult);
			return query;
		}

		// list entry names
		public function getConnectionNames():AsyncToken
		{
			return invokeAdminWithLogin("getConnectionNames", arguments);
		}
		public function getWeaveFileNames(sharedFiles:Boolean):AsyncToken
		{
			return invokeAdminWithLogin("getWeaveFileNames", arguments);
		}
		public function getKeyTypes():AsyncToken
		{
			return invokeAdminWithLogin("getKeyTypes", arguments);
		}	
		// get info
		public function getDatabaseConfigInfo():AsyncToken
		{
			return invokeAdminWithLogin("getDatabaseConfigInfo", arguments, false);
		}
                
		
		// save info
		public function saveConnectionInfo(info:ConnectionInfo, configOverwrite:Boolean):AsyncToken
		{
			var query:AsyncToken = invokeAdminWithLogin("saveConnectionInfo", [info.name, info.dbms, info.ip, info.port, info.database, info.user, info.pass, info.folderName, info.is_superuser, configOverwrite]);
			addAsyncResponder(query, alertResult);
		    return query;
		}
		public function saveWeaveFile(fileContent:ByteArray, fileName:String, overwriteFile:Boolean):AsyncToken
		{
			var query:AsyncToken = invokeAdminWithLogin("saveWeaveFile", arguments);
			//addAsyncResponder(query, alertResult);
			return query;
		}

	        	
		// remove info
		public function removeConnectionInfo(connectionNameToRemove:String):AsyncToken
		{
			var query:AsyncToken = invokeAdminWithLogin("removeConnectionInfo", arguments);
			addAsyncResponder(query, alertResult);
			return query;
		}
		public function removeDataTableInfo(tableName:String):AsyncToken
		{
			var query:AsyncToken = invokeAdminWithLogin("removeDataTableInfo", arguments);
			addAsyncResponder(query, alertResult);
			return query;
		}
		public function removeGeometryCollectionInfo(geometryCollectionName:String):AsyncToken
		{
			var query:AsyncToken = invokeAdminWithLogin("removeGeometryCollectionInfo", arguments);
			addAsyncResponder(query, alertResult);
			return query;
		}
		public function removeWeaveFile(fileName:String):AsyncToken
		{
			var query:AsyncToken = invokeAdminWithLogin("removeWeaveFile", arguments);
			addAsyncResponder(query, alertResult);
			return query;
		}
		
		public function removeAttributeColumnInfo(columnMetadata:Array):AsyncToken
		{
			var query:AsyncToken = invokeAdminWithLogin("removeAttributeColumnInfo", arguments);
			addAsyncResponder(query, alertResult);
			return query;
		}

		public function getWeaveFileInfo(fileName:String):AsyncToken
		{
			return invokeAdminWithLogin("getWeaveFileInfo", arguments, false); // bypass queue
		}
        public function testAllQueries(dataTableName:String):AsyncToken
		{
			return invokeAdminWithLogin("testAllQueries", arguments, false);
		}
		public function addChildToParent(child:int, parent:int):AsyncToken
		{
			return invokeAdminWithLogin("addChildToParent", arguments);
		}
		public function removeChildFromParent(child:int, parent:int):AsyncToken
		{
			return invokeAdminWithLogin("removeChildFromParent", arguments);
		}
		public function copyEntity(id:int):AsyncToken
		{
			return invokeAdminWithLogin("copyEntity", arguments);
		}
		public function addCategory(metadata:Object, parentId:int):AsyncToken
		{
			return invokeAdminWithLogin("addCategory", arguments);
		}
		public function addDataTable(metadata:Object):AsyncToken
		{
			return invokeAdminWithLogin("addDataTable", arguments);
		}
		public function addAttributeColumn(metadata:Object):AsyncToken
		{
			return invokeAdminWithLogin("addAttributeColumn", arguments);
		}
		public function getDataTables():AsyncToken
		{
			return invokeAdminWithLogin("getDataTables", arguments);
		}
		public function getAttributeColumns():AsyncToken
		{
			return invokeAdminWithLogin("getAttributeColumns", arguments);
		}
		public function removeEntity(id:int):AsyncToken
		{
			return invokeAdminWithLogin("removeEntity", arguments);
		}
		public function updateEntity(id:int, metadata:EntityMetadata):AsyncToken
		{
			return invokeAdminWithLogin("updateEntity", arguments);
		}
		public function getEntityParentIds(id:int):AsyncToken
		{
			return invokeAdminWithLogin("getEntityParentIds", arguments);
		}
		public function getEntityChildIds(id:int):AsyncToken
		{
			return invokeAdminWithLogin("getEntityChildIds", arguments);
		}
		public function getEntitiesById(ids:Array):AsyncToken
		{
			return invokeAdminWithLogin("getEntitiesById", arguments);
		}
		public function getEntitiesByMetadata(metadata:Object, entityType:int):AsyncToken
		{
			return invokeAdminWithLogin("getEntitiesByMetadata", arguments);
		}
		
		
		// read uploaded files
		public function uploadFile(fileName:String, content:ByteArray):AsyncToken
		{
			// queue up requests for uploading chunks at a time, then return the token of the last chunk
			
			var MB:int = ( 1024 * 1024 );
			var maxChunkSize:int = 20 * MB;
			var chunkSize:int = (content.length > (5*MB)) ? Math.min((content.length / 10 ), maxChunkSize) : ( MB );
			content.position = 0;
			
			var append:Boolean = false;
			var token:AsyncToken;
			do
			{
				var chunk:ByteArray = new ByteArray();
				content.readBytes(chunk, 0, Math.min(content.bytesAvailable, chunkSize));
				
				token = invokeAdmin('uploadFile', [fileName, chunk, append], true); // queued
				append = true;
			}
			while (content.bytesAvailable > 0);
			
			return token;
		}
		public function getServerFiles():AsyncToken
		{
			return invokeAdmin("getServerFiles", arguments);
		}
		public function getUploadedCSVFiles():AsyncToken
		{
			return invokeAdmin("getUploadedCSVFiles", arguments, false);
		}
		public function getUploadedShapeFiles():AsyncToken
		{
			return invokeAdmin("getUploadedShapeFiles", arguments, false);
		}
		public function getCSVColumnNames(csvFiles:String):AsyncToken
		{
			return invokeAdmin("getCSVColumnNames", arguments);
		}
		public function listDBFFileColumns(dbfFileName:String):AsyncToken
		{
		    return invokeAdmin("listDBFFileColumns", arguments);
		}
		public function getDBFData(dbfFileName:String):AsyncToken
		{
			return invokeAdmin("getDBFData", arguments);
		}
		
		
		// import data
		public function importCSV(csvFile:String, csvKeyColumn:String, csvSecondaryKeyColumn:String, sqlSchema:String, sqlTable:String, sqlOverwrite:Boolean, configDataTableName:String, configOverwrite:Boolean, configGeometryCollectionName:String, configKeyType:String, nullValues:String, filterColumnNames:Array):AsyncToken
		{
		    var query:AsyncToken = invokeAdminWithLogin("importCSV", arguments);
			addAsyncResponder(query, alertResult);
		    return query;
		}
		public function addConfigDataTableFromDatabase(schemaName:String, tableName:String, keyColumnName:String, secondaryKeyColumnName:String, configDataTableName:String, configOverwrite:Boolean, geometryCollectionName:String, keyType:String, filterColumns:Array):AsyncToken
		{
		    var query:AsyncToken = invokeAdminWithLogin("addConfigDataTableFromDatabase", arguments);
			addAsyncResponder(query, alertResult);
		    return query;
		}
		public function checkKeyColumnForSQLImport(schemaName:String, tableName:String, keyColumnName:String, secondaryKeyColumnName:String):AsyncToken
		{
			return invokeAdminWithLogin("checkKeyColumnForSQLImport", arguments);
		}
		public function checkKeyColumnForCSVImport(csvFileName:String, keyColumnName:String, secondaryKeyColumnName:String):AsyncToken
		{
			return invokeAdmin("checkKeyColumnForCSVImport",arguments);
		}
		public function convertShapefileToSQLStream(configfileNameWithoutExtension:String, keyColumns:Array, sqlSchema:String, sqlTablePrefix:String, sqlOverwrite:Boolean, configGeometryCollectionName:String, configOverwrite:Boolean, configKeyType:String, srsCode:String, nullValues:String, importDBFAsDataTable:Boolean):AsyncToken
		{
		    var query:AsyncToken = invokeAdminWithLogin("convertShapefileToSQLStream", arguments);
			addAsyncResponder(query, alertResult);
		    return query;
		}
		
		public function storeDBFDataToDatabase(configfileNameWithoutExtension:String, sqlSchema:String, sqlTableName:String, sqlOverwrite:Boolean, nullValues:String):AsyncToken
		{
			var query:AsyncToken = invokeAdminWithLogin("storeDBFDataToDatabase", arguments);
			addAsyncResponder(query, alertResult);
			return query;
		}
		public function saveReportDefinitionFile(filename:String, fileContents:String):AsyncToken
		{
			var query:AsyncToken = invokeAdmin("saveReportDefinitionFile", arguments);
			addAsyncResponder(query, alertResult);
			return query;
		}

		
		/**
		 * The following functions get information about the database associated with a given connection name.
		 */
		public function getSchemas():AsyncToken
		{
		    return invokeAdminWithLogin("getSchemas", arguments, false);
		}
		public function getTables(configschemaName:String):AsyncToken
		{
		    return invokeAdminWithLogin("getTables", arguments, false);
		}
		public function getColumns(configschemaName:String, tableName:String):AsyncToken
		{
		    return invokeAdminWithLogin("getColumns", arguments, false);
		}
		
		
		// data servlet functions
		
		public function getAttributeColumn(metadata:Object):AsyncToken
		{
			return invokeDataService("getAttributeColumn", arguments, false);
		}
	}
}
