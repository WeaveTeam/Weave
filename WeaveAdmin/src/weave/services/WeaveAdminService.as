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
	
	import weave.api.services.IAsyncService;
	import weave.core.CallbackCollection;
	import weave.services.beans.ConnectionInfo;
	import weave.services.beans.GeometryCollectionInfo;
	
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
		
		public function WeaveAdminService(url:String)
		{
			service = new AMF3Servlet(url + "/AdminService");
			queue = new AsyncInvocationQueue();
		}
		
		private var queue:AsyncInvocationQueue;
		private var service:AMF3Servlet;
		
		private function generateQueryAndAddToQueue(methodName:String, parameters:Array):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = new DelayedAsyncInvocation(service, methodName, parameters);
			// we want to use a queue so the admin functions will execute in the correct order.
			queue.addToQueue(query);
			// automatically display FaultEvent error messages as alert boxes
			query.addAsyncResponder(null, alertFault, query);
			return query;
		}
		// this function displays a String response from a server in an Alert box.
		private function alertResult(event:ResultEvent, token:Object = null):void
		{
			messageDisplay(null,String(event.result),false);
		}
		// this function displays an error message from a FaultEvent in an Alert box.
		private function alertFault(event:FaultEvent, token:Object = null):void
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
				msg = "Received no response from the servlet.\nHas the WAR file been deployed correctly?\nExpected servlet URL: "+ service.servletURL;
			messageDisplay(event.fault.name, msg, true);
		}

		public function checkSQLConfigExists():DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("checkSQLConfigExists", arguments);
		}
		
		public function authenticate(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("authenticate", arguments);
		}

		//public String migrateConfigToDatabase(String connectionName, String password, String schema, String geometryConfigTable, String dataConfigTable)
		public function migrateConfigToDatabase(connectionName:String, password:String, schema:String, geometryConfigTable:String, dataConfigTable:String):DelayedAsyncInvocation
		{
		    var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("migrateConfigToDatabase", arguments);
		    query.addAsyncResponder(alertResult);
		    return query;
		}


		// list entry names
		public function getConnectionNames(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("getConnectionNames", arguments);
		}
		public function getDataTableNames(connectionName:String, password:String):DelayedAsyncInvocation
		{
		    return generateQueryAndAddToQueue("getDataTableNames", arguments);
		}
		public function getGeometryCollectionNames(connectionName:String, password:String):DelayedAsyncInvocation
		{
		    return generateQueryAndAddToQueue("getGeometryCollectionNames", arguments);
		}
		public function getWeaveFileNames(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("getWeaveFileNames", arguments);
		}
		public function getKeyTypes(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("getKeyTypes", arguments);
		}

		
		// get info
		public function getDatabaseConfigInfo(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("getDatabaseConfigInfo", arguments);
		}
		public function getConnectionInfo(loginConnectionName:String, loginPassword:String, connectionNameToGet:String):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("getConnectionInfo", arguments);
		}
		public function getDataTableInfo(connectionName:String, password:String, dataTableName:String):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("getDataTableInfo", arguments);
		}
		public function getGeometryCollectionInfo(connectionName:String, password:String, geometryCollectionName:String):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("getGeometryCollectionInfo", arguments);
		}
		public function getInvalidQueryInfo(connectionName:String, password:String):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue("getInvalidQueryInfo", arguments);
		}
		
		// save info
		public function saveConnectionInfo(activeConnectionName:String, activePassword:String, info:ConnectionInfo, configOverwrite:Boolean):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("saveConnectionInfo", [activeConnectionName, activePassword, info.name, info.dbms, info.ip, info.port, info.database, info.user, info.pass, info.is_superuser, configOverwrite]);
		    query.addAsyncResponder(alertResult);
		    return query;
		}
		public function saveDataTableInfo(connectionName:String, password:String, metadata:Array):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("saveDataTableInfo", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function saveGeometryCollectionInfo(connectionName:String, password:String, info:GeometryCollectionInfo):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("saveGeometryCollectionInfo", [connectionName, password, info.name, info.connection, info.schema, info.tablePrefix, info.keyType, info.importNotes, info.projection]);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function saveWeaveFile(connectionName:String, password:String, fileContents:String, fileName:String, overwriteFile:Boolean):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("saveWeaveFile", arguments);
			//query.addAsyncResponder(alertResult);
			return query;
		}

		
		// remove info
		public function removeConnectionInfo(loginConnectionName:String, loginPassword:String, connectionNameToRemove:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("removeConnectionInfo", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function removeDataTableInfo(connectionName:String, password:String, tableName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("removeDataTableInfo", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function removeGeometryCollectionInfo(connectionName:String, password:String, geometryCollectionName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("removeGeometryCollectionInfo", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function removeWeaveFile(connectionName:String, password:String, fileName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("removeWeaveFile", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		
		public function removeAttributeColumnInfo(connectionName:String, password:String, columnMetadata:Array):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("removeAttributeColumnInfo", arguments);
			query.addAsyncResponder(alertResult);
			return query;
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
			return generateQueryAndAddToQueue("addDCElements", arguments);
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
			return generateQueryAndAddToQueue("listDCElements", arguments);
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
			return generateQueryAndAddToQueue("deleteDCElements", arguments);
		}

		public function updateEditedDCElement(connectionName:String, password:String, dataTableName:String, object:Object):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("updateEditedDCElement", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		
		
		// read uploaded files
		public function uploadFile(fileName:String, content:ByteArray):DelayedAsyncInvocation
		{
			return generateQueryAndAddToQueue('uploadFile', arguments);
		}
		public function getServerFiles():DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("getServerFiles", arguments);
			return query;
		}
		public function getUploadedCSVFiles():DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("getUploadedCSVFiles", arguments);
			return query;
		}
		public function getUploadedShapeFiles():DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("getUploadedShapeFiles", arguments);
			return query;
		}
		public function getCSVColumnNames(csvFiles:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("getCSVColumnNames", arguments);
			//query.addAsyncResponder(alertResult);
			return query;
		}
		public function listDBFFileColumns(dbfFileName:String):DelayedAsyncInvocation
		{
		    var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("listDBFFileColumns", arguments);
		    return query;
		}
		
		
		// import data
		public function importCSV(connectionName:String, password:String, csvFile:String, csvKeyColumn:String, csvSecondaryKeyColumn:String, sqlSchema:String, sqlTable:String, sqlOverwrite:Boolean, configDataTableName:String, configOverwrite:Boolean, configGeometryCollectionName:String, configKeyType:String, nullValues:String):DelayedAsyncInvocation
		{
		    var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("importCSV", arguments);
		    query.addAsyncResponder(alertResult);
		    return query;
		}
		public function addConfigDataTableFromDatabase(connectionName:String, password:String, schemaName:String, tableName:String, keyColumnName:String, secondaryKeyColumnName:String, configDataTableName:String, configOverwrite:Boolean, geometryCollectionName:String, keyType:String):DelayedAsyncInvocation
		{
		    var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("addConfigDataTableFromDatabase", arguments);
		    query.addAsyncResponder(alertResult);
		    return query;
		}
		public function convertShapefileToSQLStream(configConnectionName:String, password:String, fileNameWithoutExtension:String, keyColumns:Array, sqlSchema:String, sqlTablePrefix:String, sqlOverwrite:Boolean, configGeometryCollectionName:String, configOverwrite:Boolean, configKeyType:String, srsCode:String, nullValues:String):DelayedAsyncInvocation
		{
		    var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("convertShapefileToSQLStream", arguments);
		    query.addAsyncResponder(alertResult);
		    return query;
		}
		
		public function storeDBFDataToDatabase(configConnectionName:String, password:String, fileNameWithoutExtension:String, sqlSchema:String, sqlTableName:String, sqlOverwrite:Boolean, nullValues:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("storeDBFDataToDatabase", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}
		public function saveReportDefinitionFile(filename:String, fileContents:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("saveReportDefinitionFile", arguments);
			query.addAsyncResponder(alertResult);
			return query;
		}

		
		/**
		 * The following functions get information about the database associated with a given connection name.
		 */
		public function getSchemas(configConnectionName:String, password:String):DelayedAsyncInvocation
		{
		    return generateQueryAndAddToQueue("getSchemas", arguments);
		}
		public function getTables(configConnectionName:String, password:String, schemaName:String):DelayedAsyncInvocation
		{
		    return generateQueryAndAddToQueue("getTables", arguments);
		}
		public function getColumns(configConnectionName:String, password:String, schemaName:String, tableName:String):DelayedAsyncInvocation
		{
		    return generateQueryAndAddToQueue("getColumns", arguments);
		}
	}
}
