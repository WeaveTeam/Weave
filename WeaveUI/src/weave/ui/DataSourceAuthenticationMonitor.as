/* ***** BEGIN LICENSE BLOCK *****
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.ui
{
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;
	
	import mx.managers.PopUpManager;
	
	import weave.api.data.IDataSourceWithAuthentication;
	import weave.api.getCallbackCollection;
	import weave.core.LinkableBoolean;

	public class DataSourceAuthenticationMonitor
	{
		public static function initialize():void
		{
			WeaveAPI.globalHashMap.childListCallbacks.addGroupedCallback(null, groupedCallback, true);
		}
		
		/**
		 * This becomes true when there is at least one IDataSourceWithAuthentication that supports authentication.
		 */
		public static const authenticationSupported:LinkableBoolean = new LinkableBoolean(false);
		
		private static function groupedCallback():void
		{
			var authSupported:Boolean = false;
			for each (var dataSource:IDataSourceWithAuthentication in WeaveAPI.globalHashMap.getObjects(IDataSourceWithAuthentication))
			{
				if (_popups[dataSource] === undefined)
				{
					_popups[dataSource] = null;
					getCallbackCollection(dataSource).addGroupedCallback(null, groupedCallback);
				}
				if (dataSource.authenticationSupported)
					authSupported = true;
				if (dataSource.authenticationRequired)
					requestAuthentication(dataSource);
			}
			authenticationSupported.value = authSupported;
		}
		
		private static var _popups:Dictionary = new Dictionary(true);
		
		private static function requestAuthentication(dataSource:IDataSourceWithAuthentication):void
		{
			if (_popups[dataSource])
				return;
			
			var sourceName:String = WeaveAPI.globalHashMap.getName(dataSource);
			var popup:LoginPopup = PopUpManager.createPopUp(WeaveAPI.topLevelApplication as DisplayObject, LoginPopup, true) as LoginPopup;
			popup.title = lang("Sign in to {0}", sourceName);
			PopUpManager.centerPopUp(popup);
			popup.login = function(user:String, pass:String):void
			{
				dataSource.authenticate(user, pass);
				PopUpManager.removePopUp(popup);
				_popups[dataSource] = null;
			}
			_popups[dataSource] = popup;
		}
	}
}
