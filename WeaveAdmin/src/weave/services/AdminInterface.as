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
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.FileReference;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.rpc.events.ResultEvent;
	import mx.utils.UIDUtil;
	
	import weave.StringDefinition;
	import weave.services.beans.ConnectionInfo;
	import weave.services.beans.DatabaseConfigInfo;
	import weave.services.beans.GeometryCollectionInfo;

	public class AdminInterface
	{
		private static var _thisInstance:AdminInterface = null;
		[Bindable] public var sqlConfigExists:Boolean = true;
		[Bindable] public var sqlConfigMigrated:Boolean = true;
		[Bindable] public var currentUserIsSuperuser:Boolean = false;
		public static function get instance():AdminInterface
		{
			if (_thisInstance == null)
				_thisInstance = new AdminInterface();
			return _thisInstance;
		}
		
		public function AdminInterface()
		{
			checkSQLConfigExists();
			checkDatabaseConfigExists();
		}
		
		private function checkSQLConfigExists():void
		{
			service.checkSQLConfigExists().addAsyncResponder(handleCheckSQLConfigExists);
			function handleCheckSQLConfigExists(event:ResultEvent, token:Object = null):void
			{
				if (event.result.status as Boolean == false)
				{
					userHasAuthenticated = true;
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
		private function checkDatabaseConfigExists():void
		{
			service.checkDatabaseConfigExists().addAsyncResponder(handleCheckDatabaseConfigExists);
			function handleCheckDatabaseConfigExists(event:ResultEvent, token:Object=null):void
			{
				sqlConfigMigrated = Boolean(event.result);
			}
		}

		public const service:WeaveAdminService = new WeaveAdminService("/WeaveServices");
		
		[Bindable] public var adminActivityText:String = '';
		[Bindable] public var userHasAuthenticated:Boolean = false;
		
		// values returned by the server
		[Bindable] public var connectionNames:Array = [];
		[Bindable] public var dataTableNames:Array = [];
		[Bindable] public var geometryCollectionNames:Array = [];
		[Bindable] public var weaveFileNames:Array = [];
		[Bindable] public var keyTypes:Array = [];
		[Bindable] public var databaseConfigInfo:DatabaseConfigInfo = new DatabaseConfigInfo(null);
		
		[Bindable] public var dbfKeyColumns:Array = [];
		
		// values the user has currently selected
		[Bindable] public var activePassword:String = '';
		
		
		[Bindable] public var uploadedCSVFiles:Array = [];
		[Bindable] public var uploadedShapeFiles:Array = [];
		
		
		
		// functions for managing static settings
		public function getConnectionNames(resetActiveConnection:Boolean = true):void
		{
			// clear current list, then request new list
			connectionNames = [];
			
			service.getConnectionNames(activeConnectionName, activePassword).addAsyncResponder(handleGetConnectionNames);
			function handleGetConnectionNames(event:ResultEvent, token:Object = null):void
			{
				//trace("handleGetConnectionNames");
				connectionNames = event.result as Array || [];
	
				if (resetActiveConnection || connectionNames.indexOf(activeConnectionName) < 0)
				{
					// set activeConnectionName to first result
					if (connectionNames.length > 0)
						activeConnectionName = connectionNames[0];
					else
						activeConnectionName = StringDefinition.DEFAULT_CONNECTION;
				}
			}

			// clear current info, then request new info
			databaseConfigInfo = new DatabaseConfigInfo(null);
			if (userHasAuthenticated)
			{
				service.getDatabaseConfigInfo(activeConnectionName, activePassword).addAsyncResponder(handleGetDatabaseConfigInfo);
				function handleGetDatabaseConfigInfo(event:ResultEvent, token:Object = null):void
				{
					databaseConfigInfo = new DatabaseConfigInfo(event.result);
				}
			}
		}
		
		private var _activeConnectionName:String = StringDefinition.DEFAULT_CONNECTION;
		[Bindable] public function get activeConnectionName():String
		{
			return _activeConnectionName;
		}
		public function set activeConnectionName(value:String):void
		{
			if (_activeConnectionName != value)
			{
				_activeConnectionName = value;
				if (userHasAuthenticated)
					userHasAuthenticated = false;
				
				clearTables();
			}
		}

		/**
		 * This function will clear all the bindable array objects to prevent the user
		 * from seeing anything while logged out.
		 */
		public function clearTables():void
		{
			connectionNames = [];
			dataTableNames = [];
			geometryCollectionNames = [];
			weaveFileNames = [];
			keyTypes = [];
			databaseConfigInfo = new DatabaseConfigInfo(null);
		}
		
		public function authenticate(connectionName:String, password:String):void
		{
			if (userHasAuthenticated)
				userHasAuthenticated = false;
			activeConnectionName = connectionName;
			activePassword = password;

			service.authenticate(activeConnectionName, activePassword).addAsyncResponder(handleAuthenticate);
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
					getConnectionInfo(activeConnectionName).addAsyncResponder(handleConnectionInfo);
					function handleConnectionInfo(event:ResultEvent, token:Object = null):void
					{
						var cInfo:ConnectionInfo = new ConnectionInfo(event.result);
						currentUserIsSuperuser = cInfo.is_superuser;
					}
					
					getWeaveFileNames();
					getDataTableNames();
					getGeometryCollectionNames();
					getKeyTypes();
					getConnectionNames(false);
				}
				
			}
		}
		
		

		
		


		
		// functions for managing Weave client XML files
		
		public function getWeaveFileNames():void
		{
			weaveFileNames = [];
			service.getWeaveFileNames(activeConnectionName, activePassword).addAsyncResponder(handleGetWeaveFileNames);
			function handleGetWeaveFileNames(event:ResultEvent, token:Object = null):void
			{
				weaveFileNames = event.result as Array || [];
			}
		}
		public function removeWeaveFile(fileName:String):void
		{
			service.removeWeaveFile(
					activeConnectionName,
					activePassword,
					fileName
				);
			getWeaveFileNames();
		}
		public function initWeaveFileAndOpenWeave(fileName:String = ""):void
		{
			if ( fileName == "" )
			{
				fileName = "newClientConfig.xml";
			}
			// initialize the file on the server
			var sessionStateXML:XML = <weave encoding="dynamic">
					<WeaveDataSource name="WeaveDataSource"/>
					<ProbeToolTipEditor name="ProbeToolTipEditor"/>
				</weave>;
			// save new file if it doesn't exist (no overwrite)
			saveWeaveFile(
					sessionStateXML.toXMLString(),
					fileName,
					false
				).addAsyncResponder(handleSaveWeaveFile);
			// when file is initialized, load Weave to edit the session state.
			function handleSaveWeaveFile(e:ResultEvent, token:Object = null):void
			{
				getWeaveFileNames();
				openWeavePreview(fileName);
			}
		}





		
		
		
		
		
		// functions for managing SQL connection entries
		public function getConnectionInfo(connectionName:String):DelayedAsyncInvocation
		{
			return service.getConnectionInfo(activeConnectionName, activePassword, connectionName);
		}
		
		
		//This function only saves the connection and does not get the connection names like
		//the saveConnectionInfo function. Incase the connection fails the user won't see the 
		//other error messages if getConnectionNames function fails
		public function saveConnectionInfoOnly(connectionInfo:ConnectionInfo, configOverwrite:Boolean):void
		{
			service.saveConnectionInfo(connectionInfo, configOverwrite);
			
			//this to check if the saveConnectionInfo was successful. When the user adds the database for the first time, 
			//the Admin Console needs to know so that it can then force the user to migrate to the database.
			checkSQLConfigExists();
		}
		
		public function saveConnectionInfo(connectionInfo:ConnectionInfo, configOverwrite:Boolean):void
		{
			saveConnectionInfoOnly(connectionInfo,configOverwrite);			
			getConnectionNames();
		}
		public function removeConnectionInfo(connectionName:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = service.removeConnectionInfo(activeConnectionName, activePassword, connectionName);
			getConnectionNames();
			return query;
		}
		
		public function migrateConfigToDatabase(connectionName:String, password:String, schema:String, geometryConfig:String, dataConfig:String):DelayedAsyncInvocation
		{
			var query:DelayedAsyncInvocation = service.migrateConfigToDatabase(
				connectionName,
				password,
				schema,
				geometryConfig,
				dataConfig
			);
			query.addAsyncResponder(handler);
			function handler(event:ResultEvent, token:Object=null):void
			{
				sqlConfigMigrated = Boolean(event.result);
			}
			return query;
		}








		
			
		
		// functions for managing DataTable entries
		
		public function getDataTableNames():void
		{
			dataTableNames = [];
			
			if (userHasAuthenticated)
			{
				service.getDataTableNames(activeConnectionName, activePassword).addAsyncResponder(handlegetDataTableNames);
				function handlegetDataTableNames(event:ResultEvent, token:Object = null):void
				{
					if (userHasAuthenticated)
						dataTableNames = event.result as Array || [];
				}
			}
		}
		
		public function getDataTableInfo(dataTableName:String):DelayedAsyncInvocation
		{
			return service.getDataTableInfo(
				activeConnectionName, activePassword, dataTableName
			);
		}
		public function saveDataTableInfo(metadata:Array):void
		{
			service.saveDataTableInfo(
				activeConnectionName,
				activePassword,
				metadata
			);
			getDataTableNames();
		}
		public function removeDataTableInfo(tableName:String):void
		{
			service.removeDataTableInfo(
				activeConnectionName,
				activePassword,
				tableName
			);
			getDataTableNames();
		}


		
		
		// code for viewing CSV and Shape file on the server
		
		
		/**
		 * This function uploads a file whose content has been loaded into a FileReference object.
		 * @param fileRef The FileReference object on which load() has completed.
		 */		
		public function uploadFile(fileRef:FileReference):DelayedAsyncInvocation
		{
			return service.uploadFile(fileRef.name, fileRef.data);
		}

		public function getUploadedCSVFiles():void
		{
			uploadedCSVFiles = [];
			service.getUploadedCSVFiles().addAsyncResponder(handleUploadedCSVFiles);
			function handleUploadedCSVFiles(event:ResultEvent, token:Object = null):void
			{
				uploadedCSVFiles = event.result as Array || [];
			}
		}
		public function getUploadedShapeFiles():void
		{
			uploadedShapeFiles = [];
			service.getUploadedShapeFiles().addAsyncResponder(handleUploadedShapeFiles);
			function handleUploadedShapeFiles(event:ResultEvent, token:Object = null):void
			{
				uploadedShapeFiles = event.result as Array || [];
			}
		}



		// code for managing GeometryCollection entries
		
		public function getGeometryCollectionNames():void
		{
			geometryCollectionNames = [];
			if (userHasAuthenticated)
			{
				service.getGeometryCollectionNames(activeConnectionName, activePassword).addAsyncResponder(handleGetGeometryCollectionNames);
				function handleGetGeometryCollectionNames(event:ResultEvent, token:Object = null):void
				{
					if (userHasAuthenticated)
						geometryCollectionNames = event.result as Array || [];
				}
			}
		}
		public function getGeometryCollectionInfo(geometryCollectionName:String):DelayedAsyncInvocation
		{
			return service.getGeometryCollectionInfo(
				activeConnectionName, activePassword, geometryCollectionName
			);
		}
		public function saveGeometryCollectionInfo(info:GeometryCollectionInfo):void
		{
			service.saveGeometryCollectionInfo(activeConnectionName, activePassword, info);
			getGeometryCollectionNames();
		}
		public function removeGeometryCollectionInfo(geometryCollectionName:String):void
		{
			service.removeGeometryCollectionInfo(
				activeConnectionName,
				activePassword,
				geometryCollectionName
			);
			getGeometryCollectionNames();
		}






		
		public function getKeyTypes():void
		{
			keyTypes = [];
			if (userHasAuthenticated)
			{
				service.getKeyTypes(activeConnectionName, activePassword).addAsyncResponder(handleGetKeyTypes);
				function handleGetKeyTypes(event:ResultEvent, token:Object = null):void
				{
					if (userHasAuthenticated)
						keyTypes = event.result as Array || [];
				}
			}
		}








		// functions for importing data
		
		public function storeDBFDataToDatabase(
			importDBFFileNameInputToStore:String, 
			importDBFSchemaComboToStore:String,
			importDBFTableInputToStore:String,
			importDBFDataToSQLOverwriteCheck:Boolean,
			importDBFButton:Button,
			nullValues:String):void
		{
					var alertTitle:String = "Missing parameter";
					if (importDBFFileNameInputToStore == '')
						Alert.show("You must upload a shape file and a corresponding DBF file.", alertTitle);
					else if (importDBFSchemaComboToStore == '')
						Alert.show("You must specify sql schema to store the table.", alertTitle);
					else if (importDBFTableInputToStore == '')
						Alert.show("You must specify the name of the destination SQL table.", alertTitle);
					else
					{
						importDBFButton.enabled = false;
						var enableImportDBFButton:Function = function(...args):void
						{
							importDBFButton.enabled = true;
						};
						service.storeDBFDataToDatabase(
							activeConnectionName,
							activePassword,
							importDBFFileNameInputToStore,
							importDBFSchemaComboToStore,
							importDBFTableInputToStore,
							importDBFDataToSQLOverwriteCheck,
							nullValues
						).addAsyncResponder(enableImportDBFButton, enableImportDBFButton);
					}
		}
		public function listDBFFileColumns(dbfFileName:String):void
		{
			service.listDBFFileColumns(dbfFileName).addAsyncResponder(handleListDBFFileColumns);
		}
		private function handleListDBFFileColumns(event:ResultEvent, token:Object = null):void
		{
			dbfKeyColumns = event.result as Array || [];
		}
		
		public function convertShapefileToSQLStream(fileName:String, keyColumns:Array, sqlSchema:String, sqlTable:String, 
													tableOverwriteCheck:Boolean, geometryCollection:String, configOverwriteCheck:Boolean, 
													keyType:String, srsCode:String, nullValues:String):void
		{
			service.convertShapefileToSQLStream(
				activeConnectionName,
				activePassword,
				fileName,
				keyColumns,
				sqlSchema,
				sqlTable,
				tableOverwriteCheck,
				geometryCollection,
				configOverwriteCheck,
				keyType,
				srsCode,
				nullValues
			);
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
								  nullValues:String	):DelayedAsyncInvocation
		{
			var asyncToken:DelayedAsyncInvocation = service.importCSV(
				activeConnectionName,
				activePassword,
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
				nullValues
			);
			
			getDataTableNames();
			
			return asyncToken;
		}
		
		public function addConfigDataTableFromDatabase(sqlSchema:String, sqlTable:String, keyColumn:String, secondaryKeyColumn:String, tableName:String, overwrite:Boolean, geometryCollection:String, keyType:String):void
		{
				service.addConfigDataTableFromDatabase(
					activeConnectionName,
					activePassword,
					sqlSchema,
					sqlTable,
					keyColumn,
					secondaryKeyColumn,
					tableName,
					overwrite,
					geometryCollection,
					keyType
				);
				getDataTableNames();
		}
		









		//LocalConnection Code
		
		// this function is for verifying the local connection between Weave and the AdminConsole.
		public function ping():String { return "pong"; }
		
		public function openWeavePreview(fileName:String):void
		{
			var connectionName:String = createWeaveService();
			ExternalInterface.call(
					'function(){ window.open("weave.html?defaults='+fileName+'&connectionName='+connectionName+'","_blank","width=800,height=600,location=0,toolbar=0,menubar=0,resizable=1") }'
				);
		}
		
		public function saveWeaveFile(sessionState:String, clientConfigFileName:String, fileOverwrite:Boolean):DelayedAsyncInvocation
		{
			if (clientConfigFileName.length < 4 ||
				clientConfigFileName.substr(clientConfigFileName.length - 4).toLowerCase() != '.xml')
			{
				clientConfigFileName += '.xml';
			}
			
			var query:DelayedAsyncInvocation = service.saveWeaveFile(
				activeConnectionName,
				activePassword,
				sessionState,
				clientConfigFileName,
				fileOverwrite
			);
			query.addAsyncResponder(displayFileSaveStatus);
			function displayFileSaveStatus(event:ResultEvent, token:Object = null):void
			{
				adminActivityText += event.result + '\n';
			}
			getWeaveFileNames();
			return query;
		}

		private var weaveService:LocalAsyncService = null; // the current service object
		// creates a new LocalAsyncService and returns its corresponding connection name.
		private function createWeaveService():String
		{
			if (weaveService)
			{
				// Attempt close the popup window of the last service that was created.
				//					var token:AsyncToken = weaveService.invokeAsyncMethod('closeWeavePopup');
				//					DelayedAsyncResponder.addResponder(token, handleCloseWeavePopup, null, weaveService);
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
		
		
		public function showHelpForKeyType():void
		{
			Alert.show(
				'If two tables have compatible keys, you should give them the same key type.  ' +
				'If two tables have incompatible keys, they should not have the same key type.  ' +
				'Weave only allows two columns to be compared if they have the same key type.',
				'Admin Console Help'
			);
		}









		// dublin core functionality
		
		/**
		 * Adds the given Dublin Core key-value pairs to the metadata store for
		 * the dataset with the given name.
		 * @param datasetName the name of the dataset to associate the new element values with
		 * @param elements an Object (map) whose keys are strings such as "dc:title", "dc:description", etc.
		 * and whose values are the (String) values for those elements, applied to the dataset with the given name.
		 * @param callback (optional) a function called when the server returns (of signature function(e:Event, token:Object = null):void)
		 */ 
		public function addDCElements(datasetName:String,elements:Object,callback:Function = null):void{
			var query:DelayedAsyncInvocation = service.addDCElements(activeConnectionName,activePassword,datasetName,elements);
			if(callback != null)
				query.addAsyncResponder(callback);
		}

		/**
		 * Requests from the server a list of Dublin Core metadata elements for the data table with the given name.
		 */
		public function listDCElements(dataTableName:String):DelayedAsyncInvocation
		{
			return service.listDCElements(
				activeConnectionName, activePassword, dataTableName
			);
		}
		
		/**
		 * Deletes the specified Dublin Core element entries.
		 */
		public function deleteDCElements(dataTableName:String,elements:Array):DelayedAsyncInvocation
		{
			return service.deleteDCElements(
				activeConnectionName, activePassword, dataTableName, elements
			);
		}
		/**
		 * Updates the edited Dublin Core element entry.
		 */
		public function updateEditedDCElement(dataTableName:String, object:Object):DelayedAsyncInvocation
		{
			return service.updateEditedDCElement(
				activeConnectionName, activePassword, dataTableName, object
			);
		}
		
		
		/* ********************************************* */
		/* Audio and Video Functions Not yet Implemented */
		/* ********************************************* */
		
		
	}
}
