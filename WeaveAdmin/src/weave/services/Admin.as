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
	import flash.utils.Dictionary;
	
	import mx.rpc.events.ResultEvent;
	import mx.utils.StringUtil;
	import mx.utils.UIDUtil;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.services.beans.DatabaseConfigInfo;
	import weave.services.beans.EntityHierarchyInfo;

	public class Admin
	{
		private static var _thisInstance:Admin = null;
		public static function get instance():Admin
		{
			if (_thisInstance == null)
				_thisInstance = new Admin();
			return _thisInstance;
		}
		public static function get service():WeaveAdminService
		{
			return instance.service;
		}
		public static function get entityCache():EntityCache
		{
			return instance.entityCache;
		}
		
		
		private var _service:WeaveAdminService = null;
		public function get service():WeaveAdminService
		{
			if (!_service)
				_service = new WeaveAdminService("/WeaveServices");
			return _service;
		}

		private var focusEntityId:int = -1;
		/**
		 * This is an entity id on which editors should focus, or -1 if none.
		 * It will be set to the newest entity that was created by the administrator.
		 * After an editor has focused on the entity, clearFocusEntityId() should be called.
		 */
		public function getFocusEntityId():int
		{
			return focusEntityId;
		}
		public function clearFocusEntityId():void
		{
			focusEntityId = -1;
		}
		
		private var _entityCache:EntityCache = null;
		public function get entityCache():EntityCache
		{
			if (!_entityCache)
				_entityCache = new EntityCache();
			return _entityCache;
		}
		
		
		[Bindable] public var databaseConfigExists:Boolean = true;
		[Bindable] public var currentUserIsSuperuser:Boolean = false;
		[Bindable] public var userHasAuthenticated:Boolean = false;
		
		// values returned by the server
		[Bindable] public var connectionNames:Array = [];
		[Bindable] public var weaveFileNames:Array = [];
		[Bindable] public var privateWeaveFileNames:Array = [];
		[Bindable] public var keyTypes:Array = [];
		[Bindable] private var dataTypes:Array = [];
		[Bindable] public var databaseConfigInfo:DatabaseConfigInfo = new DatabaseConfigInfo(null);
		
		// values the user has currently selected
		[Bindable] public var activePassword:String = '';
		
		[Bindable] public var uploadedCSVFiles:Array = [];
		[Bindable] public var uploadedShapeFiles:Array = [];
		
		private var _activeConnectionName:String = '';
		

		
		public function Admin()
		{
			///////////////////
			// Initialization
			service.addHook(
				service.checkDatabaseConfigExists,
				null,
				function handleCheck(event:ResultEvent, token:Object):void
				{
					// save info
					databaseConfigExists = event.result as Boolean;
					if (!databaseConfigExists)
						service.getConnectionNames();
				}
			);
			service.addHook(
				service.authenticate,
				function(connectionName:String, password:String):void
				{
					// not logged in until result comes back
					if (userHasAuthenticated)
						userHasAuthenticated = false;
					
					activeConnectionName = connectionName;
					activePassword = password;
				},
				function(event:ResultEvent, token:Object):void
				{
					// save info
					userHasAuthenticated = true;
					currentUserIsSuperuser = event.result as Boolean;
					
					// refresh lists
					service.getWeaveFileNames(false);
					service.getWeaveFileNames(true);
					service.getConnectionNames();
					service.getDatabaseConfigInfo();
					service.getKeyTypes();
				}
			);
			//////////////////////////////
			// Weave client config files
			service.addHook(
				service.saveWeaveFile,
				null,
				function(event:ResultEvent, token:Object):void
				{
					WeaveAdminService.messageDisplay(null, event.result as String, false);
					
					// refresh lists
					service.getWeaveFileNames(false);
					service.getWeaveFileNames(true);
				}
			);
			service.addHook(
				service.removeWeaveFile,
				null,
				function(..._):void
				{
					// refresh lists
					service.getWeaveFileNames(false);
					service.getWeaveFileNames(true);
				}
			);
			service.addHook(
				service.getWeaveFileNames,
				null,
				function(event:ResultEvent, user_pass_showAllFiles:Array):void
				{
					var showAllFiles:Boolean = user_pass_showAllFiles[2];
					if (showAllFiles)
						weaveFileNames = event.result as Array || [];
					else
						privateWeaveFileNames = event.result as Array || [];
				}
			);
			//////////////////////////////
			// ConnectionInfo management
			service.addHook(
				service.getConnectionNames,
				null,
				function(event:ResultEvent, token:Object):void
				{
					// save list
					connectionNames = event.result as Array || [];
				}
			);
 			service.addHook(
				service.saveConnectionInfo,
				null,
				function(event:ResultEvent, args:Array):void
				{
					// when connection save succeeds and we just changed our password, change our login credentials
					// 0=activeName, 1=activePass, 2=saveName, 3=savePass, 4=folderName, 5=is_superuser, 6=connectString, 7=overwrite
					var activeName:String = args[0];
					var saveName:String = args[2];
					var savePass:String = args[3];
					if (!userHasAuthenticated)
					{
						activeConnectionName = saveName;
						activePassword = savePass;
					}
					else if (activeName == saveName && activeConnectionName == saveName)
					{
						activePassword = savePass;
					}
					
					// refresh list
					service.getConnectionNames();
					service.getDatabaseConfigInfo();
				}
			);
			service.addHook(
				service.removeConnectionInfo,
				null,
				function(event:ResultEvent, user_pass_connectionNameToRemove:Array):void
				{
					var activeUser:String = user_pass_connectionNameToRemove[0];
					var removedUser:String = user_pass_connectionNameToRemove[2];
					// if user removed self, log out
					if (activeUser == removedUser)
					{
						activeConnectionName = '';
						activePassword = '';
					}
					else
					{
						// refresh list
						service.getConnectionNames();
						service.getDatabaseConfigInfo();
					}
				}
			);
			//////////////////////////////////
			// DatabaseConfigInfo management
			service.addHook(
				service.getDatabaseConfigInfo,
				null,
				function(event:ResultEvent, token:Object):void
				{
					// save info
					databaseConfigInfo = new DatabaseConfigInfo(event.result);
				}
			);
			service.addHook(
				service.setDatabaseConfigInfo,
				null,
				function(event:ResultEvent, token:Object):void
				{
					// save info
					databaseConfigExists = Boolean(event.result);
					if (activeConnectionName && activePassword)
					{
						if (!userHasAuthenticated)
							service.authenticate(activeConnectionName, activePassword);
					
						// refresh
						service.getDatabaseConfigInfo();
					}
					// purge cache
					entityCache.invalidateAll(true);
				}
			);
			/////////////////
			// File uploads
			service.addHook(
				service.getUploadedCSVFiles,
				null,
				function(event:ResultEvent, token:Object):void
				{
					// save info
					uploadedCSVFiles = event.result as Array || [];
				}
			);
			service.addHook(
				service.getUploadedSHPFiles,
				null,
				function(event:ResultEvent, token:Object):void
				{
					// save info
					uploadedShapeFiles = event.result as Array || [];
				}
			);
			////////////////
			// Data import
			service.addHook(service.importSQL, null, handleTableImportResult);
			service.addHook(service.importCSV, null, handleTableImportResult);
			service.addHook(service.importSHP, null, handleTableImportResult);
			//////////////////
			// Miscellaneous
			service.addHook(
				service.getKeyTypes,
				null,
				function(event:ResultEvent, token:Object):void
				{
					// save list
					if (userHasAuthenticated)
					{
						keyTypes = event.result as Array || [];
						dataTypes = keyTypes.concat();
						dataTypes.unshift(DataTypes.NUMBER, DataTypes.STRING, DataTypes.GEOMETRY);
					}
				}
			);
			service.addHook(
				service.newEntity,
				null,
				function(event:ResultEvent, user0_pass1_type2_meta3_parent4_index5:Array):void
				{
					var id:int = int(event.result);
					focusEntityId = id;
					entityCache.invalidate(id);
					var parentId:int = user0_pass1_type2_meta3_parent4_index5[4];
					entityCache.invalidate(parentId);
				}
			);
			
			service.checkDatabaseConfigExists();
		}
		
		private function handleTableImportResult(event:ResultEvent, token:Object):void
		{
			var tableId:int = int(event.result);
			var info:EntityHierarchyInfo = entityCache.getBranchInfo(tableId);
			if (info)
				weaveTrace(lang('Existing data table "{0}" was updated successfully.', info.title));
			else
				weaveTrace(lang("New data table created successfully."));
			
			focusEntityId = tableId;
			// request children
			entityCache.invalidate(tableId, true);
			for each (var id:int in entityCache.getEntity(tableId).childIds)
				entityCache.invalidate(id);
			// refresh list
			service.getKeyTypes();
		}
			
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
			weaveFileNames = [];
			privateWeaveFileNames = [];
			keyTypes = [];
			dataTypes = [];
			databaseConfigInfo = new DatabaseConfigInfo(null);
		}
		
		

		//////////////////////////////////////////
		// LocalConnection Code
		
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
			weaveService = new LocalAsyncService(service, true, connectionName);
			return connectionName;
		}

		private var oldWeaveServices:Dictionary = new Dictionary(); // the keys are pointers to old service objects
		private function handleCloseWeavePopup(event:ResultEvent, service:LocalAsyncService):void
		{
			trace("handleCloseWeavePopup");
			service.dispose();
			delete oldWeaveServices[service];
		}
		// End of LocalConnection Code
		//////////////////////////////////////////
		
		
		
		public function getSuggestedPropertyValues(propertyName:String):Array
		{
			switch (propertyName)
			{
				case 'connection':
					return connectionNames;
				
				case ColumnMetadata.DATA_TYPE:
					return dataTypes;
				
				case ColumnMetadata.KEY_TYPE:
					return keyTypes;
				
				default:
					return null;
			}
		}
	}
}
