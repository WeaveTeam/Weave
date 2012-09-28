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
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.StringUtil;
	
	import weave.core.CallbackCollection;
	import weave.services.beans.ConnectionInfo;
	import weave.services.beans.GeometryCollectionInfo;
	
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
		private function invokeAdminService(methodName:String, parameters:Array, queued:Boolean = true):DelayedAsyncInvocation
		{
			if (queued)
				return generateQueryAndAddToQueue(adminService, methodName, parameters);
			return adminService.invokeAsyncMethod(methodName, parameters) as DelayedAsyncInvocation;
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
                        function outputToConsole(event:ResultEvent, token:Object = null):void
                        {
                               messageDisplay("Query sent:", String(token), false);
                        }
			query.addAsyncResponder(outputToConsole, alertFault, query);
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
			var query:DelayedAsyncInvocation = token as DelayedAsyncInvocation;
			
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

		public function checkSQLConfigExists():DelayedAsyncInvocation
		{
			return invokeAdminService("checkSQLConfigExists", arguments);
		}
		
		public function authenticate(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return invokeAdminService("authenticate", arguments);
		}

                public function getConnectionInfo(loginConnectionName:String, loginPassword:String, connectionNameToGet:String):DelayedAsyncInvocation
                {
                        return invokeAdminService("getConnectionInfo", arguments, false);
                }
                //public String setDatabaseConfigInfo(String connectionName, String password, String schema) 
                public function setDatabaseConfigInfo(connectionName:String, password:String, schema:String):DelayedAsyncInvocation
                {
                    var query:DelayedAsyncInvocation = invokeAdminService("setDatabaseConfigInfo", arguments);
                    query.addAsyncResponder(alertResult);
                    return query;
                }
		//public String migrateConfigToDatabase(String connectionName, String password, String schema)
//		public function migrateConfigToDatabase(connectionName:String, password:String, schema:String):DelayedAsyncInvocation
//		{
//		    var query:DelayedAsyncInvocation = invokeAdminService("migrateConfigToDatabase", arguments);
//		    query.addAsyncResponder(alertResult);
//		    return query;
//		}

		// list entry names
		public function getConnectionNames(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return invokeAdminService("getConnectionNames", arguments);
		}
		public function getWeaveFileNames(connectionName:String, password:String, sharedFiles:Boolean):DelayedAsyncInvocation
		{
			return invokeAdminService("getWeaveFileNames", arguments);
		}
		public function getKeyTypes(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return invokeAdminService("getKeyTypes", arguments);
		}	
		// get info
		public function getDatabaseConfigInfo(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return invokeAdminService("getDatabaseConfigInfo", arguments, false);
		}
                
		
		// save info
		public function saveConnectionInfo(activeConnectionName:String, activePassword:String, info:ConnectionInfo, configOverwrite:Boolean):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("saveConnectionInfo", [activeConnectionName, activePassword, info.name, info.dbms, info.ip, info.port, info.database, info.user, info.pass, info.folderName, info.is_superuser, configOverwrite]);
		    query.addAsyncResponder(alertResult);
		    return query;
		}
		public function saveWeaveFile(connectionName:String, password:String, fileContent:ByteArray, fileName:String, overwriteFile:Boolean):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("saveWeaveFile", arguments);
			//query.addAsyncResponder(alertResult);
			return query;
		}

	        	
		// remove info
		public function removeConnectionInfo(loginConnectionName:String, loginPassword:String, connectionNameToRemove:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("removeConnectionInfo", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function removeDataTableInfo(connectionName:String, password:String, tableName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("removeDataTableInfo", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function removeGeometryCollectionInfo(connectionName:String, password:String, geometryCollectionName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("removeGeometryCollectionInfo", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function removeWeaveFile(connectionName:String, password:String, fileName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("removeWeaveFile", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		
		public function removeAttributeColumnInfo(connectionName:String, password:String, columnMetadata:Array):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("removeAttributeColumnInfo", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}

		public function getWeaveFileInfo(connectionName:String, password:String, fileName:String):DelayedAsyncInvocation
		{
			return invokeAdminService("getWeaveFileInfo", arguments, false); // bypass queue
		}
	        public function testAllQueries(connectionName:String, password:String, dataTableName:String):DelayedAsyncInvocation
                {
                    return invokeAdminService("testAllQueries", arguments, false);
                }
                public function addChildToParent(connectionName:String, password:String, child:int, parent:int):DelayedAsyncInvocation
                {
                        return invokeAdminService("addChildToParent", arguments);
                }
                public function removeChildFromParent(connectionName:String, password:String, child:int, parent:int):DelayedAsyncInvocation{
                        return invokeAdminService("removeChildFromParent", arguments);
                }
                public function copyEntity(connectionName:String, password:String, id:int):DelayedAsyncInvocation{
                        return invokeAdminService("copyEntity", arguments);
                }
                public function addTag(connectionName:String, password:String, metadata:Object):DelayedAsyncInvocation{
                        return invokeAdminService("addTag", arguments);
                }
                public function addDataTable(connectionName:String, password:String, metadata:Object):DelayedAsyncInvocation{
                        return invokeAdminService("addDataTable", arguments);
                }
                public function addAttributeColumn(connectionName:String, password:String, metadata:Object):DelayedAsyncInvocation{
                        return invokeAdminService("addAttributeColumn", arguments);
                }
                public function getTags(connectionName:String, password:String):DelayedAsyncInvocation{
                        return invokeAdminService("getTags", arguments);
                }
                public function getDataTables(connectionName:String, password:String):DelayedAsyncInvocation{
                        return invokeAdminService("getDataTables", arguments);
                }
                public function getAttributeColumns(connectionName:String, password:String):DelayedAsyncInvocation{
                        return invokeAdminService("getAttributeColumns", arguments);
                }

                public function removeEntity(connectionName:String, password:String, id:int):DelayedAsyncInvocation{
                        return invokeAdminService("removeEntity", arguments);
                }
                public function updateEntity(connectionName:String, password:String, id:int, metadata:Object):DelayedAsyncInvocation
                {
                        return invokeAdminService("updateEntity", arguments);
                }
                public function getEntityChildren(connectionName:String, password:String, id:int):DelayedAsyncInvocation
                {
                        return invokeAdminService("getEntityChildren", arguments);
                }
                public function getEntity(connectionName:String, password:String, id:int):DelayedAsyncInvocation
                {
                        return invokeAdminService("getEntity", arguments);
                }
                public function getEntities(connectionName:String, password:String, metadata:Object):DelayedAsyncInvocation
                {
                        return invokeAdminService("getEntities", arguments);
                }
                public function getEntitiesWithType(connectionName:String, password:String, type_id:int, metadata:Object):DelayedAsyncInvocation
                {
                        return invokeAdminService("getEntitiesWithType", arguments);
                }
		/**
		 * Adds the given Dublin Core key-value pairs to the metadata store for
		 * the dataset with the given name.
		 * @param connectionName the name of the current connection
		 * @param password the password to use for access to the current connection
		 * @param datasetName the name of the dataset to associate the new element values with
		 * @param elements an Object (map) whose keys are strings such as "dc:title", "dc:description", etc.
		 * and whose values are the (String) values for those elements, applied to the dataset with the given name.
		 */ 
		public function addDCElements(connectionName:String, password:String, datasetName:String,elements:Object):DelayedAsyncInvocation{
			return invokeAdminService("addDCElements", arguments);
		}
		
		/**
		 * Lists the Dublin Core key-value pairs currently in the metadata store for
		 * the dataset with the given name.
		 * @param connectionName the name of the current connection
		 * @param password the password to use for access to the current connection
		 * @param datasetName the name of the data table to associate the new element values with
		 * @param elements an Object (map) whose keys are strings such as "dc:title", "dc:description", etc.
		 * and whose values are the (String) values for those elements, applied to the dataset with the given name.
		 */ 
		public function listDCElements(connectionName:String, password:String, datasetName:String):DelayedAsyncInvocation{
			return invokeAdminService("listDCElements", arguments);
		}
			
		/**
		 * Deletes the given Dublin Core key-value pairs to the metadata store for
		 * the dataset with the given name.
		 * @param connectionName the name of the current connection
		 * @param password the password to use for access to the current connection
		 * @param dataTableName the name of the data table to associate the new element values with
		 * @param elements an Object (map) whose keys are strings such as "dc:title", "dc:description", etc.
		 * and whose values are the (String) values for those elements, applied to the dataset with the given name. These will be deleted.
		 */ 
		public function deleteDCElements(connectionName:String, password:String, dataTableName:String, elements:Array):DelayedAsyncInvocation{
			return invokeAdminService("deleteDCElements", arguments);
		}

		public function updateEditedDCElement(connectionName:String, password:String, dataTableName:String, object:Object):DelayedAsyncInvocation
		{
			return invokeAdminService("updateEditedDCElement", arguments);
		}
		
		
		// read uploaded files
		public function uploadFile(fileName:String, content:ByteArray):DelayedAsyncInvocation
		{
			return invokeAdminService('uploadFile', arguments);
		}
		public function getServerFiles():DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("getServerFiles", arguments);
			return query;
		}
		public function getUploadedCSVFiles():DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("getUploadedCSVFiles", arguments, false);
			return query;
		}
		public function getUploadedShapeFiles():DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("getUploadedShapeFiles", arguments, false);
			return query;
		}
		public function getCSVColumnNames(csvFiles:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("getCSVColumnNames", arguments);
			//query.addAsyncResponder(alertResult);
			return query;
		}
		public function getCSVStringData(csvFile:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("getCSVStringData", arguments);
			//query.addAsyncResponder(alertResult);
			return query;
		}
		public function listDBFFileColumns(dbfFileName:String):DelayedAsyncInvocation
		{
		    var query:DelayedAsyncInvocation = invokeAdminService("listDBFFileColumns", arguments);
		    return query;
		}
		public function getDBFData(dbfFileName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("getDBFData", arguments);
			return query;
		}
		
		
		// import data
		public function importCSV(connectionName:String, password:String, csvFile:String, csvKeyColumn:String, csvSecondaryKeyColumn:String, sqlSchema:String, sqlTable:String, sqlOverwrite:Boolean, configDataTableName:String, configOverwrite:Boolean, configGeometryCollectionName:String, configKeyType:String, nullValues:String, filterColumnNames:Array):DelayedAsyncInvocation
		{
		    var query:DelayedAsyncInvocation = invokeAdminService("importCSV", arguments);
		    query.addAsyncResponder(alertResult);
		    return query;
		}
		public function addConfigDataTableFromDatabase(connectionName:String, password:String, schemaName:String, tableName:String, keyColumnName:String, secondaryKeyColumnName:String, configDataTableName:String, configOverwrite:Boolean, geometryCollectionName:String, keyType:String, filterColumns:Array):DelayedAsyncInvocation
		{
		    var query:DelayedAsyncInvocation = invokeAdminService("addConfigDataTableFromDatabase", arguments);
		    query.addAsyncResponder(alertResult);
		    return query;
		}
		public function checkKeyColumnForSQLImport(connectionName:String, password:String, schemaName:String, tableName:String, keyColumnName:String, secondaryKeyColumnName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("checkKeyColumnForSQLImport", arguments);
			return query;
		}
		public function checkKeyColumnForCSVImport(csvFileName:String, keyColumnName:String, secondaryKeyColumnName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("checkKeyColumnForCSVImport",arguments);
			return query;
		}
		public function convertShapefileToSQLStream(configConnectionName:String, password:String, fileNameWithoutExtension:String, keyColumns:Array, sqlSchema:String, sqlTablePrefix:String, sqlOverwrite:Boolean, configGeometryCollectionName:String, configOverwrite:Boolean, configKeyType:String, srsCode:String, nullValues:String, importDBFAsDataTable:Boolean):DelayedAsyncInvocation
		{
		    var query:DelayedAsyncInvocation = invokeAdminService("convertShapefileToSQLStream", arguments);
		    query.addAsyncResponder(alertResult);
		    return query;
		}
		
		public function storeDBFDataToDatabase(configConnectionName:String, password:String, fileNameWithoutExtension:String, sqlSchema:String, sqlTableName:String, sqlOverwrite:Boolean, nullValues:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("storeDBFDataToDatabase", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function saveReportDefinitionFile(filename:String, fileContents:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = invokeAdminService("saveReportDefinitionFile", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}

		
		/**
		 * The following functions get information about the database associated with a given connection name.
		 */
		public function getSchemas(configConnectionName:String, password:String):DelayedAsyncInvocation
		{
		    return invokeAdminService("getSchemas", arguments, false);
		}
		public function getTables(configConnectionName:String, password:String, schemaName:String):DelayedAsyncInvocation
		{
		    return invokeAdminService("getTables", arguments, false);
		}
		public function getColumns(configConnectionName:String, password:String, schemaName:String, tableName:String):DelayedAsyncInvocation
		{
		    return invokeAdminService("getColumns", arguments, false);
		}
		
		
		// data servlet functions
		
		public function getAttributeColumn(metadata:Object):DelayedAsyncInvocation
		{
			return invokeDataService("getAttributeColumn", arguments, false);
		}
		
		
	}
}
