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

package weave.menus
{
	import flash.display.DisplayObject;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import mx.managers.PopUpManager;
	
	import weave.Weave;
	import weave.compiler.StandardLib;
	import weave.editors.WeavePropertiesEditor;
	import weave.ui.AlertTextBox;
	import weave.ui.AlertTextBoxEvent;
	import weave.ui.DraggablePanel;
	import weave.ui.SessionStateEditor;
	import weave.ui.collaboration.CollaborationTool;

	public class SystemMenu extends WeaveMenuItem
	{
		private static const OPEN_NEW_SESSION:String = 'openNewSession';
		public static function newSessionPossible():Boolean
		{
			return WeaveAPI.topLevelApplication.hasOwnProperty(OPEN_NEW_SESSION)
				&& WeaveAPI.topLevelApplication[OPEN_NEW_SESSION] is Function;
		}
		public static function openNewSession():void
		{
			WeaveAPI.topLevelApplication[OPEN_NEW_SESSION]()
		}
		
		private function go_to_url(item:WeaveMenuItem):void
		{
			navigateToURL(new URLRequest(item.data as String), "_blank");
		}
		private static const VERSION:String = 'version';
		
		private function managePlugins():void
		{
			var popup:AlertTextBox;
			popup = PopUpManager.createPopUp(WeaveAPI.topLevelApplication as DisplayObject, AlertTextBox) as AlertTextBox;
			popup.allowEmptyInput = true;
			popup.textInput = WeaveAPI.CSVParser.createCSVRow(Weave.getPluginList());
			popup.title = lang("Specify which plugins to load");
			popup.message = lang("List plugin .SWC files, separated by commas. Weave will reload itself if plugins have to be unloaded.");
			popup.addEventListener(
				AlertTextBoxEvent.BUTTON_CLICKED,
				function(event:AlertTextBoxEvent):void {
					if (event.confirm)
					{
						var plugins:Array = WeaveAPI.CSVParser.parseCSVRow(event.textInput) || [];
						Weave.setPluginList(plugins, null);
					}
				}
			);
			PopUpManager.centerPopUp(popup);
		}
		
		public function SystemMenu()
		{
			super({
				label: lang("Weave"),
				children: [
					{
						shown: {or: [FileMenu.fn_adminMode, Weave.properties.enableUserPreferences]},
						label: lang("Preferences"),
						click: function():void { DraggablePanel.openStaticInstance(WeavePropertiesEditor); }
					},{
						label: lang("Edit Session State"),
						click: SessionStateEditor.openDefaultEditor
					},
					TYPE_SEPARATOR,
					{
						shown: Weave.properties.enableManagePlugins,
						label: lang("Manage plugins"),
						click: managePlugins
					},
					TYPE_SEPARATOR,
					{
						shown: Weave.properties.showCollaborationMenuItem,
						label: function():String {
							var collabTool:CollaborationTool = CollaborationTool.instance;
							if (collabTool && collabTool.collabService.isConnected)
								return lang("Open collaboration window");
							else
								return lang("Connect to collaboration server");
						},
						click: function():void { DraggablePanel.openStaticInstance(CollaborationTool); }
					},
					TYPE_SEPARATOR,
					{
						label: lang("Report a problem"),
						click: go_to_url,
						data: "http://info.iweave.com/projects/weave/issues/new"
					},{
						label: lang("Visit {0}", "iWeave.com"),
						click: go_to_url,
						data: "http://www.iweave.com"
					},{
						label: lang("Visit {0}", "Weave Wiki"),
						click: go_to_url,
						data: "http://info.iweave.com/projects/weave/wiki"
					},
					TYPE_SEPARATOR,
					{
						label: function():String {
							var version:String = Weave.properties.version.value;
							var app:Object = WeaveAPI.topLevelApplication;
							if (app && app.hasOwnProperty(VERSION))
								version = StandardLib.substitute("{0} ({1})", version, app[VERSION]);
							return lang("Version: {0}", version);
						},
						enabled: false
					},
					TYPE_SEPARATOR,
					{
						shown: JavaScript.available,
						label: lang("Restart"),
						click: Weave.externalReload
					},{
						label: lang("New session"),
						shown: newSessionPossible,
						click: openNewSession
					}
				]
			});
		}
	}
}
