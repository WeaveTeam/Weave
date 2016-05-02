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

package weave.services
{
	import flash.utils.Dictionary;
	import flash.net.URLRequest;

	import mx.controls.Alert;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.AsyncToken;
	import mx.utils.UIDUtil;
	import mx.utils.URLUtil;
	
	import weave.api.linkBindableProperty;
	import weave.api.linkableObjectIsBusy;
	import weave.api.data.ColumnMetadata;
	import weave.api.services.beans.Entity;
	import weave.api.services.beans.EntityHierarchyInfo;
	import weave.services.URLRequestUtils;
	import weave.compiler.StandardLib;
	import weave.services.beans.DatabaseConfigInfo;

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
			{
				_service = new WeaveAdminService("/WeaveServices");
				linkBindableProperty(_service.authenticated, this, 'userHasAuthenticated');
			}
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
			// if the entity does not exist on the server, don't attempt to focus on it
			if (!linkableObjectIsBusy(entityCache) && !entityCache.entityIsCached(focusEntityId))
				focusEntityId = -1;
			return focusEntityId;
		}
		public function setFocusEntityId(id:int):void
		{
			// Request the entity now so that we can later detect if it
			// exists on the server by checking entityCache.entityIsCached().
			entityCache.getEntity(id);
			focusEntityId = id;
		}
		public function clearFocusEntityId():void
		{
			focusEntityId = -1;
		}
		
		private var _entityCache:EntityCache = null;
		public function get entityCache():EntityCache
		{
			if (!_entityCache)
				_entityCache = new EntityCache(service, true);
			return _entityCache;
		}
		
		
		[Bindable] public var databaseConfigExists:Boolean = true;
		[Bindable] public var currentUserIsSuperuser:Boolean = false;

		private var _userHasAuthenticated:Boolean = false;
		[Bindable] public function get userHasAuthenticated():Boolean
		{
			return _userHasAuthenticated;
		}
		public function set userHasAuthenticated(value:Boolean):void
		{
			_userHasAuthenticated = value;
			if (!_userHasAuthenticated)
			{
				// prevent the user from seeing anything while logged out.
				entityCache.invalidateAll(true);
				currentUserIsSuperuser = false;
				connectionNames = [];
				weaveFileNames = [];
				privateWeaveFileNames = [];
				keyTypes = [];
				databaseConfigInfo = new DatabaseConfigInfo();
			}
		}
		
		// values returned by the server
		[Bindable] public var connectionNames:Array = [];
		[Bindable] public var weaveFileNames:Array = [];
		[Bindable] public var privateWeaveFileNames:Array = [];
		[Bindable] public var keyTypes:Array = [];
		[Bindable] public var databaseConfigInfo:DatabaseConfigInfo = new DatabaseConfigInfo();
		/**
		 * An Array of WeaveFileInfo objects.
		 * @see weave.services.beans.WeaveFileInfo
		 */
		[Bindable] public var uploadedCSVFiles:Array = [];
		/**
		 * An Array of WeaveFileInfo objects.
		 * @see weave.services.beans.WeaveFileInfo
		 */
		[Bindable] public var uploadedShapeFiles:Array = [];
		
		public function Admin()
		{
			///////////////////
			// Initialization
			service.addHook(
				service.checkDatabaseConfigExists,
				null,
				function handleCheck(event:ResultEvent, _:*):void
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
				function(event:ResultEvent, _:*):void
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
				function(event:ResultEvent, _:*):void
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
				function(event:ResultEvent, args:Array):void
				{
					var showAllFiles:Boolean = args[0];
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
				function(event:ResultEvent, _:*):void
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
					// 0=user, 1=pass, 2=folderName, 3=is_superuser, 4=connectString, 5=overwrite
					var saveName:String = args[0];
					var savePass:String = args[1];
					if (!userHasAuthenticated)
					{
						activeConnectionName = saveName;
						activePassword = savePass;
					}
					else if (activeConnectionName == saveName)
					{
						activePassword = savePass;
					}
					
					// refresh lists that may have changed
					service.getConnectionNames();
					service.getDatabaseConfigInfo();
					service.getWeaveFileNames(false);
				}
			);
			service.addHook(
				service.removeConnectionInfo,
				null,
				function(event:ResultEvent, args:Array):void
				{
					var removedUser:String = args[0];
					// if user removed self, log out
					if (activeConnectionName == removedUser)
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
				function(event:ResultEvent, _:*):void
				{
					// save info
					databaseConfigInfo = DatabaseConfigInfo(event.result) || new DatabaseConfigInfo();
				}
			);
			service.addHook(
				service.setDatabaseConfigInfo,
				null,
				function(event:ResultEvent, _:*):void
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
				function(event:ResultEvent, _:*):void
				{
					// save info
					uploadedCSVFiles = event.result as Array || [];
				}
			);
			service.addHook(
				service.getUploadedSHPFiles,
				null,
				function(event:ResultEvent, _:*):void
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
				function(event:ResultEvent, _:*):void
				{
					// save list
					if (userHasAuthenticated)
						keyTypes = event.result as Array || [];
				}
			);
			service.addHook(
				service.newEntity,
				null,
				function(event:ResultEvent, meta0_parent1_index2:Array):void
				{
					var id:int = int(event.result);
					focusEntityId = id;
					entityCache.invalidate(id);
					var parentId:int = meta0_parent1_index2[1];
					entityCache.invalidate(parentId);
				}
			);
			
			service.checkDatabaseConfigExists();
		}
		
		private function handleTableImportResult(event:ResultEvent, _:*):void
		{
			var tableId:int = int(event.result);
			var exists:Boolean = false;
			var title:String;
			var info:EntityHierarchyInfo = entityCache.getBranchInfo(tableId);
			if (info)
			{
				exists = true;
				title = info.title;
			}
			else if (entityCache.entityIsCached(tableId))
			{
				exists = true;
				var entity:Entity = entityCache.getEntity(tableId);
				title = entity.publicMetadata[ColumnMetadata.TITLE];
			}
			
			if (exists)
				weaveTrace(lang('Existing data table "{0}" was updated successfully.', title));
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
			return service.user;
		}
		public function set activeConnectionName(value:String):void
		{
			if (service.user == value)
				return;
			service.user = value;
			
			// log out
			userHasAuthenticated = false;
		}
		[Bindable] public function get activePassword():String
		{
			return service.pass;
		}
		public function set activePassword(value:String):void
		{
			service.pass = value;
		}

		//////////////////////////////////////////
		// LocalConnection Code
		
		private static const ADMIN_SESSION_WINDOW_NAME_PREFIX:String = "WeaveAdminSession";

		private static const WEAVE_FLASH_URL:String = "weave.html";
		private static const WEAVE_JS_URL:String = "weave-html5/";

		public static function checkWeaveAvailability():void {
			Admin.checkWeaveFlashAvailability();
			Admin.checkWeaveJsAvailability();
		}

		private static function checkWeaveFlashAvailability():void {
			var token:AsyncToken = WeaveAPI.URLRequestUtils.getURL(Admin, new URLRequest(WEAVE_FLASH_URL));
			addAsyncResponder(token, function ():void {
				Admin.weaveFlashIsAvailable = true;
			}, function():void { Admin.weaveFlashIsAvailable = false; });
		}

		private static function checkWeaveJsAvailability():void {
			var token:AsyncToken = WeaveAPI.URLRequestUtils.getURL(Admin, new URLRequest(WEAVE_JS_URL+"index.html"));
			addAsyncResponder(token, function ():void {
				Admin.weaveJsIsAvailable = true;
			}, function():void { Admin.weaveJsIsAvailable = false; });
		}

		[Bindable] public static var weaveJsIsAvailable:Boolean = false;
		[Bindable] public static var weaveFlashIsAvailable:Boolean = false;
		[Bindable] public var useWeaveJs:Boolean = false;

		public static function weaveClientLabelFunc(item:Object):String
		{
			return item ? 'WeaveJS': 'Flash Weave';
		}
		
		public function getWeaveURL(fileName:String, recover:Boolean = false):String
		{
			var flashVars:Object = WeaveAPI.topLevelApplication.root.loaderInfo.parameters || {};
			var weaveUrl:String;
			var params:Object = {};

			if (fileName)
				params['file'] = fileName;
			if (recover)
				params['recover'] = true;

			if (weaveJsIsAvailable && !weaveFlashIsAvailable) useWeaveJs = true; /* You are on the cutting edge. */

			if (!useWeaveJs)
			{
				weaveUrl = flashVars['weaveUrl'] || WEAVE_FLASH_URL;
			}
			else
			{
				weaveUrl = WEAVE_JS_URL;
				if (params['file'])
					params['file'] = "../" + params['file'];
			}

			return URLUtil.getFullURL(WeaveAPI.topLevelApplication.url, weaveUrl + '?' + StandardLib.replace(URLUtil.objectToString(params, '&'), '%2F', '/'));
		}

		public function openWeavePopup(fileName:String = null, recover:Boolean = false):void
		{
			var success:Boolean = JavaScript.exec(
				{
					url: getWeaveURL(fileName),
					target: ADMIN_SESSION_WINDOW_NAME_PREFIX + createWeaveSession()
				},
				'return !!window.open(url, target);'
			);
			if (!success)
				Alert.show("Please enable popups in your web browser.", "Popup blocked")
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
			var connectionName:String = StandardLib.replace(UIDUtil.createUID(), '-', '');
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
			var suggestions:Array = ColumnMetadata.getSuggestedPropertyValues(propertyName);
			switch (propertyName)
			{
				case 'connection':
					return connectionNames;
				
				case ColumnMetadata.KEY_TYPE:
					return keyTypes;
				
				case ColumnMetadata.DATA_TYPE:
					return suggestions.concat(keyTypes);
				
				default:
					return suggestions;
			}
		}
	}
}
