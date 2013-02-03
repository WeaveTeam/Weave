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
				function handleCheck(event:ResultEvent, token:Object = null):void
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
				function(event:ResultEvent, token:Object = null):void
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
				function(event:ResultEvent, token:Object = null):void
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
				function(event:ResultEvent, arguments:Array):void
				{
					// save list
					var showAllFiles:Boolean = arguments[0];
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
				function(event:ResultEvent, token:Object = null):void
				{
					// save list
					connectionNames = event.result as Array || [];
				}
			);
 			service.addHook(
				service.saveConnectionInfo,
				null,
				function(event:ResultEvent, arguments:Array):void
				{
					// refresh list
					service.getConnectionNames();
					service.getDatabaseConfigInfo();
				}
			);
			service.addHook(
				service.removeConnectionInfo,
				null,
				function(event:ResultEvent, arguments:Array):void
				{
					// if user removed self, log out
					if (arguments[0] == arguments[2])
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
				function(event:ResultEvent, token:Object = null):void
				{
					// save info
					databaseConfigInfo = new DatabaseConfigInfo(event.result);
				}
			);
			service.addHook(
				service.setDatabaseConfigInfo,
				null,
				function(event:ResultEvent, token:Object=null):void
				{
					// save info
					databaseConfigExists = Boolean(event.result);
					
					// refresh
					service.getDatabaseConfigInfo();
					entityCache.clearCache();
				}
			);
			/////////////////
			// File uploads
			service.addHook(
				service.getUploadedCSVFiles,
				null,
				function(event:ResultEvent, token:Object = null):void
				{
					// save info
					uploadedCSVFiles = event.result as Array || [];
				}
			);
			service.addHook(
				service.getUploadedSHPFiles,
				null,
				function(event:ResultEvent, token:Object = null):void
				{
					// save info
					uploadedShapeFiles = event.result as Array || [];
				}
			);
			////////////////
			// Data import
			service.addHook(
				service.importSQL,
				null,
				function(event:ResultEvent, token:Object = null):void
				{
					// request children
					entityCache.invalidate(int(event.result), true);
					// refresh list
					service.getKeyTypes();
				}
			);
			service.addHook(
				service.importCSV,
				null,
				function(event:ResultEvent, token:Object = null):void
				{
					// request children
					entityCache.invalidate(int(event.result), true);
					// refresh list
					service.getKeyTypes();
				}
			);
			service.addHook(
				service.importSHP,
				null,
				function(event:ResultEvent, token:Object = null):void
				{
					// request children
					entityCache.invalidate(int(event.result), true);
					// refresh list
					service.getKeyTypes();
				}
			);
			service.addHook(
				service.importDBF,
				null,
				function(event:ResultEvent, token:Object = null):void
				{
					// request children
					entityCache.invalidate(int(event.result), true);
					// refresh list
					service.getKeyTypes();
				}
			);
			//////////////////
			// Miscellaneous
			service.addHook(
				service.getKeyTypes,
				null,
				function(event:ResultEvent, token:Object = null):void
				{
					// save list
					if (userHasAuthenticated)
						keyTypes = event.result as Array || [];
				}
			);
			
			service.checkDatabaseConfigExists();
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
			databaseConfigInfo = new DatabaseConfigInfo(null);
		}
		
		

		//////////////////////////////////////////
		// LocalConnection Code
		
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
		// End of LocalConnection Code
		//////////////////////////////////////////
		
		
		
		public function getSuggestedPropertyValues(propertyName:String):Array
		{
			switch (propertyName)
			{
				case 'connection':
					return connectionNames;
				
				case ColumnMetadata.DATA_TYPE:
					return [DataTypes.NUMBER, DataTypes.STRING, DataTypes.GEOMETRY];
				
				case ColumnMetadata.KEY_TYPE:
					return keyTypes;
				
				default:
					return null;
			}
		}
	}
}
