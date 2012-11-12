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
		[Bindable] public var databaseConfigExists:Boolean = true;
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
			service.addHook(
				service.importSQL,
				function(event:ResultEvent, token:Object = null):void
				{
					entityCache.invalidate(int(event.result), true);
					service.getKeyTypes();
				}
			);
			service.addHook(
				service.checkDatabaseConfigExists,
				function handleCheck(event:ResultEvent, token:Object = null):void
				{
					if (event.result.status as Boolean == false)
					{
						userHasAuthenticated = false;
						WeaveAdminService.messageDisplay("Configuration problem", String(event.result.comment), false);
						//Alert.show(event.result.comment, "Configuration problem");
						databaseConfigExists = false;
					}
					else 
					{
						databaseConfigExists = true;
					}
				}
			);
			service.addHook(
				service.getConnectionNames,
				function(event:ResultEvent, token:Object = null):void
				{
					connectionNames = event.result as Array || [];
				}
			);
			service.addHook(
				service.getDatabaseConfigInfo,
				function(event:ResultEvent, token:Object = null):void
				{
					databaseConfigInfo = new DatabaseConfigInfo(event.result);
				}
			);
			service.addHook(
				service.authenticate,
				function(event:ResultEvent, token:Object = null):void
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
						service.getWeaveFileNames(false);
						service.getWeaveFileNames(true);
						service.getConnectionNames();
						service.getKeyTypes();
					}
				}
			);
			service.addHook(
				service.saveWeaveFile,
				function(event:ResultEvent, token:Object = null):void
				{
					WeaveAdminService.messageDisplay(null, event.result as String, false);
					service.getWeaveFileNames(false);
					service.getWeaveFileNames(true);
				}
			);
			service.addHook(
				service.removeWeaveFile,
				function(..._):void
				{
					service.getWeaveFileNames(false);
					service.getWeaveFileNames(true);
				}
			);
			service.addHook(
				service.getWeaveFileNames,
				function(event:ResultEvent, arguments:Array):void
				{
					var showAllFiles:Boolean = arguments[0];
					if (showAllFiles)
						weaveFileNames = event.result as Array || [];
					else
						privateWeaveFileNames = event.result as Array || [];
				}
			);
			service.addHook(
				service.saveConnectionInfo,
				function(event:ResultEvent, arguments:Array):void
				{
					getConnectionNames();
				}
			);
			service.addHook(
				service.removeConnectionInfo,
				function(event:ResultEvent, arguments:Array):void
				{
					getConnectionNames();
				}
			);
			service.addHook(
				service.setDatabaseConfigInfo,
				function(event:ResultEvent, token:Object=null):void
				{
					databaseConfigExists = Boolean(event.result);
				}
			);
			service.addHook(
				service.getUploadedCSVFiles,
				function(event:ResultEvent, token:Object = null):void
				{
					uploadedCSVFiles = event.result as Array || [];
				}
			);
			service.addHook(
				service.getUploadedSHPFiles,
				function(event:ResultEvent, token:Object = null):void
				{
					uploadedShapeFiles = event.result as Array || [];
				}
			);
			service.addHook(
				service.getDBFColumnNames,
				function(event:ResultEvent, token:Object = null):void
				{
					dbfKeyColumns = event.result as Array || [];
				}
			);
			service.addHook(
				service.getDBFData,
				function(event:ResultEvent, token:Object = null):void
				{
					dbfData = event.result as Array || [];
				}
			);
			service.addHook(
				service.importCSV,
				function(event:ResultEvent, token:Object = null):void
				{
					entityCache.invalidate(int(event.result), true);
					service.getKeyTypes();
				}
			);
			service.addHook(
				service.importSHP,
				function(event:ResultEvent, token:Object = null):void
				{
					entityCache.invalidate(int(event.result), true);
					service.getKeyTypes();
				}
			);
			service.addHook(
				service.importDBF,
				function(event:ResultEvent, token:Object = null):void
				{
					entityCache.invalidate(int(event.result), true);
					service.getKeyTypes();
				}
			);
			service.addHook(
				service.getKeyTypes,
				function(event:ResultEvent, token:Object = null):void
				{
					if (userHasAuthenticated)
						keyTypes = event.result as Array || [];
				}
			);
			
			service.checkDatabaseConfigExists();
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
			
			service.getConnectionNames();
			service.getDatabaseConfigInfo()
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

			return service.authenticate();
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
