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
	import flash.external.ExternalInterface;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	import mx.utils.StringUtil;
	import mx.utils.UIDUtil;
	
	import weave.services.beans.ConnectionInfo;
	import weave.services.beans.DatabaseConfigInfo;
	import weave.services.beans.Entity;

	public class AdminInterface
	{
		private static var _thisInstance:AdminInterface = null;
		[Bindable] public var sqlConfigExists:Boolean = true;
		[Bindable] public var currentUserIsSuperuser:Boolean = false;
		public static function get instance():AdminInterface
		{
			if (_thisInstance == null)
				_thisInstance = new AdminInterface();
			return _thisInstance;
		}
		public static function get service():WeaveAdminService
		{
			return instance.service;
		}
		
		public function AdminInterface()
		{
			checkSQLConfigExists();
		}
		
		private function checkSQLConfigExists():void
		{
			addAsyncResponder(service.checkSQLConfigExists(), handleCheckSQLConfigExists);
			function handleCheckSQLConfigExists(event:ResultEvent, token:Object = null):void
			{
				if (event.result.status as Boolean == false)
				{
					userHasAuthenticated = false;
					WeaveAdminService.messageDisplay("Configuration problem", String(event.result.comment), false);
					//Alert.show(event.result.comment, "Configuration problem");
					sqlConfigExists = false;
				}
				else 
				{
					sqlConfigExists = true;
				}
			}
		}

		public const service:WeaveAdminService = new WeaveAdminService("/WeaveServices");
		
		[Bindable] public var userHasAuthenticated:Boolean = false;
		
		// values returned by the server
		[Bindable] public var connectionNames:Array = [];
		[Bindable] public var columnTree:Array = [];
		[Bindable] public var columnIds:Object = {};
		[Bindable] public var dataTableNames:Array = [];
		[Bindable] public var geometryCollectionNames:Array = [];
		[Bindable] public var weaveFileNames:Array = [];
		[Bindable] public var privateWeaveFileNames:Array = [];
		[Bindable] public var keyTypes:Array = [];
		[Bindable] public var databaseConfigInfo:DatabaseConfigInfo = new DatabaseConfigInfo(null);
		
		[Bindable] public var dbfKeyColumns:Array = [];
		
		[Bindable] public var dbfData:Array = [];
		
		// values the user has currently selected
		[Bindable] public var activePassword:String = '';
		
		
		[Bindable] public var uploadedCSVFiles:Array = [];
		[Bindable] public var uploadedShapeFiles:Array = [];
		
		
		
		public const entityCache:EntityCache = new EntityCache();
		// functions for managing static settings
		public function getConnectionNames():void
		{
			// clear current info, then request new info
			connectionNames = [];
			databaseConfigInfo = new DatabaseConfigInfo(null);
			
			addAsyncResponder(service.getConnectionNames(), handleGetConnectionNames);
			function handleGetConnectionNames(event:ResultEvent, token:Object = null):void
			{
				//trace("handleGetConnectionNames");
				connectionNames = event.result as Array || [];
			}

			addAsyncResponder(service.getDatabaseConfigInfo(), handleGetDatabaseConfigInfo);
			function handleGetDatabaseConfigInfo(event:ResultEvent, token:Object = null):void
			{
				databaseConfigInfo = new DatabaseConfigInfo(event.result);
			}
		}
		
		private var _activeConnectionName:String = '';
		[Bindable] public function get activeConnectionName():String
		{
			return _activeConnectionName;
		}
		public function set activeConnectionName(value:String):void
		{
			if (_activeConnectionName == value)
				return;
			_activeConnectionName = value;
			
			// log out and prevent the user from seeing anything while logged out.
			userHasAuthenticated = false;
			currentUserIsSuperuser = false;
			connectionNames = [];
			dataTableNames = [];
			geometryCollectionNames = [];
			weaveFileNames = [];
			privateWeaveFileNames = [];
			keyTypes = [];
			databaseConfigInfo = new DatabaseConfigInfo(null);
		}
		
		public function authenticate(connectionName:String, password:String):AsyncToken
		{
			if (userHasAuthenticated)
				userHasAuthenticated = false;
			activeConnectionName = connectionName;
			activePassword = password;

			var query:AsyncToken = service.authenticate();
			addAsyncResponder(query, handleAuthenticate);
			function handleAuthenticate(event:ResultEvent, token:Object = null):void
			{
				if (userHasAuthenticated != event.result as Boolean)
					userHasAuthenticated = event.result as Boolean;
				if (!userHasAuthenticated)
				{
					//Alert.show("Incorrect password.", "Login failed");
					WeaveAdminService.messageDisplay("Login Failed","Incorrect password",false);
				}
				else
				{
					addAsyncResponder(service.getConnectionInfo(activeConnectionName), handleConnectionInfo);
					function handleConnectionInfo(event:ResultEvent, token:Object = null):void
					{
						var cInfo:ConnectionInfo = new ConnectionInfo(event.result);
						currentUserIsSuperuser = cInfo.is_superuser;
					}
					
					/* Do we really want to do this on auth? */
					getWeaveFileNames();
					getPrivateWeaveFileNames();
					getConnectionNames();
					//getDataTableNames();
					//getGeometryCollectionNames();
					//getKeyTypes();
				}
			}
			return query;
		}
		
		

		
		


		
		// functions for managing Weave client XML files
		
		public function getWeaveFileNames():void
		{
			weaveFileNames = [];
			addAsyncResponder(service.getWeaveFileNames(true), handleGetWeaveFileNames);
			function handleGetWeaveFileNames(event:ResultEvent, token:Object = null):void
			{
				weaveFileNames = event.result as Array || [];
			}
		}
		
		public function getPrivateWeaveFileNames():void
		{
			privateWeaveFileNames = [];
			addAsyncResponder(service.getWeaveFileNames(false), handleGetWeaveFileNames);
			function handleGetWeaveFileNames(event:ResultEvent, token:Object = null):void
			{
				privateWeaveFileNames = event.result as Array || [];
			}
		}
		
		public function removeWeaveFile(fileName:String):AsyncToken
		{
			var query:AsyncToken = service.removeWeaveFile(fileName);
			addAsyncResponder(query, handler);
			function handler(..._):void
			{
				getWeaveFileNames();
				getPrivateWeaveFileNames(); //temporary solution instead of adding another function remove private weave files
			}
			return query;
		}





		
		
		
		
		
		public function saveConnectionInfo(connectionInfo:ConnectionInfo, configOverwrite:Boolean):AsyncToken
		{
			var query:AsyncToken = service.saveConnectionInfo(connectionInfo, configOverwrite);
			addAsyncResponder(query, handler);
			function handler(..._):void
			{
				getConnectionNames();
			}
			return query;
		}

		public function removeConnectionInfo(connectionName:String):AsyncToken
		{
			var query:AsyncToken = service.removeConnectionInfo(connectionName);
			addAsyncResponder(query, handler);
			function handler(..._):void
			{
				getConnectionNames();
			}
			return query;
		}
		
		public function setDatabaseConfigInfo(connectionName:String, password:String, schema:String):AsyncToken
		{
			var query:AsyncToken = service.setDatabaseConfigInfo(
				connectionName,
				password,
				schema
			);
			addAsyncResponder(query, handler);
			function handler(event:ResultEvent, token:Object=null):void
			{
				sqlConfigExists = Boolean(event.result);
				//TODO: Should we really do this cosmetic thing here?
				//getDataTableNames();
				//getGeometryCollectionNames();
				getKeyTypes();
			}
			return query;
		}
		// functions for managing DataTable entries
		public function getDataTableInfo(title:String):AsyncToken
		{
		    var params:Object = {"title": title};
		    return service.getEntitiesByType(Entity.TYPE_COLUMN, params);
		}
		public function getDataTables():void
		{
			dataTableNames = [];
			
			if (userHasAuthenticated)
			{
				addAsyncResponder(service.getDataTables(), handlegetDataTableNames);
				function handlegetDataTableNames(event:ResultEvent, token:Object = null):void
				{
					if (userHasAuthenticated)
						dataTableNames = event.result as Array || [];
				}
			}
		}
		

		// code for viewing CSV and Shape file on the server
		
		
		public function getUploadedCSVFiles():AsyncToken
		{
			uploadedCSVFiles = [];
			var query:AsyncToken = service.getUploadedCSVFiles();
			addAsyncResponder(query, handleUploadedCSVFiles);
			function handleUploadedCSVFiles(event:ResultEvent, token:Object = null):void
			{
				uploadedCSVFiles = event.result as Array || [];
			}
			return query;
		}
		public function getUploadedShapeFiles():AsyncToken
		{
			uploadedShapeFiles = [];
			var query:AsyncToken = service.getUploadedShapeFiles();
			addAsyncResponder(query, handleUploadedShapeFiles);
			function handleUploadedShapeFiles(event:ResultEvent, token:Object = null):void
			{
				uploadedShapeFiles = event.result as Array || [];
			}
			return query;
		}








		/**
		 * @return Either an AsyncToken, or null if the user has not authenticated yet.
		 */
		public function getKeyTypes():AsyncToken
		{
			keyTypes = [];
			if (userHasAuthenticated)
			{
				var query:AsyncToken = service.getKeyTypes();
				addAsyncResponder(query, handleGetKeyTypes);
				function handleGetKeyTypes(event:ResultEvent, token:Object = null):void
				{
					if (userHasAuthenticated)
						keyTypes = event.result as Array || [];
				}
				return query;
			}
			return null;
		}




		// functions for importing data
		
		public function storeDBFDataToDatabase(fileName:String, sqlSchema:String, sqlTable:String, sqlOverwrite:Boolean, nullValues:String):AsyncToken
		{
			var query:AsyncToken = service.storeDBFDataToDatabase(
				fileName,
				sqlSchema,
				sqlTable,
				sqlOverwrite,
				nullValues
			);
			addAsyncResponder(query, handler);
			function handler(..._):void
			{
				getDataTables();
				getKeyTypes();
			}
			return query;
		}
		public function listDBFFileColumns(dbfFileName:String):AsyncToken
		{
			var query:AsyncToken = service.listDBFFileColumns(dbfFileName);
			addAsyncResponder(query, handleListDBFFileColumns);
			function handleListDBFFileColumns(event:ResultEvent, token:Object = null):void
			{
				dbfKeyColumns = event.result as Array || [];
			}
			return query;
		}
		public function getDBFData(dbfFileName:String):AsyncToken
		{
			var query:AsyncToken = service.getDBFData(dbfFileName);
			addAsyncResponder(query, handleGetDBFData);
			function handleGetDBFData(event:ResultEvent, token:Object = null):void
			{
				dbfData = event.result as Array || [];
			}
			return query;
		}
		
		public function convertShapefileToSQLStream(fileName:String, keyColumns:Array, sqlSchema:String, sqlTable:String, 
													tableOverwriteCheck:Boolean, geometryCollection:String, configOverwriteCheck:Boolean, 
													keyType:String, srsCode:String, nullValues:String,importDBFAsDataTable:Boolean):AsyncToken
		{
			var query:AsyncToken = service.convertShapefileToSQLStream(
				fileName,
				keyColumns,
				sqlSchema,
				sqlTable,
				tableOverwriteCheck,
				geometryCollection,
				configOverwriteCheck,
				keyType,
				srsCode,
				nullValues,
				importDBFAsDataTable
			);
			addAsyncResponder(query, handler);
			function handler(..._):void
			{
				//getDataTableNames();
				//getGeometryCollectionNames();
				getKeyTypes();
			}
			return query;
		}
		
		/**
		 * TODO add documentation for all parameters.
		 */
		public function importCSV(csvFileName:String,
								  keyColumn:String,
								  secondaryKeyColumn:String,
								  sqlSchema:String,
								  sqlTable:String,
								  tableOverwriteCheck:Boolean,
								  dataTableName:String,
								  dataTableOverwriteCheck:Boolean,
								  geometryCollectionName:String,
								  keyType:String,
								  nullValues:String, 
								  filterColumnNames:Array):AsyncToken
		{
			var query:AsyncToken = service.importCSV(
				csvFileName,
				keyColumn,
				secondaryKeyColumn,
				sqlSchema,
				sqlTable,
				tableOverwriteCheck,
				dataTableName,
				dataTableOverwriteCheck,
				geometryCollectionName,
				keyType,
				nullValues,
				filterColumnNames
			);
			
			addAsyncResponder(query, handler);
			function handler(..._):void
			{
				getDataTables();
				getKeyTypes();
			}
			
			return query;
		}
		
		public function addConfigDataTableFromDatabase(sqlSchema:String, sqlTable:String, keyColumn:String, secondaryKeyColumn:String, tableName:String, overwrite:Boolean, geometryCollection:String, keyType:String, filterColumns:Array):AsyncToken
		{
			var query:AsyncToken = service.addConfigDataTableFromDatabase(
				sqlSchema,
				sqlTable,
				keyColumn,
				secondaryKeyColumn,
				tableName,
				overwrite,
				geometryCollection,
				keyType,
				filterColumns
			);
			addAsyncResponder(query, handler);
			function handler(..._):void
			{
				getDataTables();
				getKeyTypes();
			}
			return query;
		}
		
		


		//LocalConnection Code
		
		// this function is for verifying the local connection between Weave and the AdminConsole.
		public function ping():String { return "pong"; }
		
		public function openWeavePopup(fileName:String = null, recover:Boolean = false):void
		{
			var url:String = 'weave.html?';
			if (fileName)
				url += 'file=' + fileName + '&'
			url += 'adminSession=' + createWeaveSession();
			
			if (recover)
				url += '&recover=true';
			
			var target:String = '_blank';
			var params:String = 'width=1000,height=740,location=0,toolbar=0,menubar=0,resizable=1';
			
			// use setTimeout so it will call later without blocking ActionScript
			var script:String = StringUtil.substitute('setTimeout(function(){ window.open("{0}", "{1}", "{2}"); }, 0)', url, target, params);
			ExternalInterface.call(script);
		}
		
		public function saveWeaveFile(fileContent:ByteArray, clientConfigFileName:String, fileOverwrite:Boolean):AsyncToken
		{
			var query:AsyncToken = service.saveWeaveFile(
				fileContent,
				clientConfigFileName,
				fileOverwrite
			);
			addAsyncResponder(query, displayFileSaveStatus);
			function displayFileSaveStatus(event:ResultEvent, token:Object = null):void
			{
				WeaveAdminService.messageDisplay(null, event.result as String, false);
				getWeaveFileNames();
				getPrivateWeaveFileNames(); //temporary solution
			}
			return query;
		}

		private var weaveService:LocalAsyncService = null; // the current service object
		// creates a new LocalAsyncService and returns its corresponding connection name.
		private function createWeaveSession():String
		{
			if (weaveService)
			{
				// Attempt close the popup window of the last service that was created.
				//					var token:AsyncToken = weaveService.invokeAsyncMethod('closeWeavePopup');
				//					addAsyncResponder(token, handleCloseWeavePopup, null, weaveService);
				// Keep the service in oldWeaveServices Dictionary because this invocation may fail if the popup window is still loading.
				// This may result in zombie service objects, but it won't matter much.
				// It is important to make sure any existing popup windows can still communicate back to the Admin Console.
				oldWeaveServices[weaveService] = null; // keep a pointer to this old service object until the popup window is closed.
			}
			// create a new service with a new name
			var connectionName:String = UIDUtil.createUID(); // NameUtil.createUniqueName(this);
			weaveService = new LocalAsyncService(this, true, connectionName);
			return connectionName;
		}

		private var oldWeaveServices:Dictionary = new Dictionary(); // the keys are pointers to old service objects
		private function handleCloseWeavePopup(event:ResultEvent, token:Object = null):void
		{
			trace("handleCloseWeavePopup");
			(token as LocalAsyncService).dispose();
			delete oldWeaveServices[token];
		}
		//End of LocalConnection Code
	}
}
