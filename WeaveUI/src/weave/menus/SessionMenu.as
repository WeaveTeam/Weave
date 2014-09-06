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

package weave.menus
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	
	import mx.managers.PopUpManager;
	
	import weave.Weave;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_File;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.linkableObjectIsBusy;
	import weave.api.reportError;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.KeySets.KeySet;
	import weave.menus.WeaveMenuItem;
	import weave.ui.AlertTextBox;
	import weave.ui.AlertTextBoxEvent;
	import weave.ui.DraggablePanel;
	import weave.ui.ExportSessionStateOptions;
	import weave.ui.SessionStateEditor;
	import weave.ui.collaboration.CollaborationTool;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.PopUpUtils;

	public class SessionMenu extends WeaveMenuItem
	{
		// TODO: make it so we are not dependent on VisApplication implementation
		private function loadSessionState(fileContent:Object, fileName:String):void
		{
			WeaveAPI.topLevelApplication['visApp']['loadSessionState'](fileContent, fileName);
		}
		private function saveSessionStateToServer():void
		{
			WeaveAPI.topLevelApplication['visApp']['saveSessionStateToServer']();
		}
		public static function fn_adminMode():Boolean
		{
			return WeaveAPI.topLevelApplication['visApp']['adminMode'];
		}
		public static function fn_adminService():Boolean
		{
			return WeaveAPI.topLevelApplication['visApp']['adminService'] ? true : false;
		}
		//-----------
		
		private var _weaveFileRef:FileReference;
		private function importSessionHistory():void
		{
			try
			{
				if (!_weaveFileRef)
				{
					_weaveFileRef = new FileReference();
					_weaveFileRef.addEventListener(Event.SELECT,   function (e:Event):void {
						_weaveFileRef.load();
					});
					_weaveFileRef.addEventListener(Event.COMPLETE, function (e:Event):void {
						loadSessionState(e.target.data, _weaveFileRef.name);
					});
				}
				_weaveFileRef.browse([
					new FileFilter(lang("Weave files"), "*.weave"),
					new FileFilter(lang("All files"), "*.*")
				]);
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		private function managePlugins():void
		{
			var popup:AlertTextBox;
			popup = PopUpManager.createPopUp(WeaveAPI.topLevelApplication as DisplayObject, AlertTextBox) as AlertTextBox;
			popup.allowEmptyInput = true;
			popup.textInput = WeaveAPI.CSVParser.createCSVRow(Weave.getPluginList());
			popup.title = lang("Specify which plugins to load");
			popup.message = lang("List plugin .SWC files, separated by commas. Weave will reload itself if plugins have to be unloaded.");
			popup.addEventListener(AlertTextBoxEvent.BUTTON_CLICKED, handlePluginsChange);
			PopUpManager.centerPopUp(popup);
		}
		private function handlePluginsChange(event:AlertTextBoxEvent):void
		{
			if (event.confirm)
			{
				var plugins:Array = WeaveAPI.CSVParser.parseCSVRow(event.textInput) || [];
				Weave.setPluginList(plugins, null);
			}
		}
		
		/**
		 * Removes all IDataSources, resets all ReferencedColumns/KeySets, clears history.
		 */
		public static function createTemplate():void
		{
			for each (var name:String in WeaveAPI.globalHashMap.getNames(IDataSource))
				WeaveAPI.globalHashMap.removeObject(name);
			
			var columns:Array = getLinkableDescendants(WeaveAPI.globalHashMap, ReferencedColumn);
			for each (var rc:ReferencedColumn in columns)
				rc.setColumnReference(null, null);
			
			var keySets:Array = getLinkableDescendants(WeaveAPI.globalHashMap, KeySet);
			for each (var keySet:KeySet in keySets)
				keySet.clearKeys();
			
			for each (var file:String in WeaveAPI.URLRequestUtils.getLocalFileNames())
				WeaveAPI.URLRequestUtils.removeLocalFile(file);
			
			Weave.history.clearHistory();
			
			Weave.properties.isTemplate.value = true;
		}
		
		/**
		 * Initializes the current session state as a template using a data source.
		 * @param fileSource The data source. 
		 * @return true if the current session state looks like a template.
		 */
		public static function initTemplate(fileSource:IDataSource_File):Boolean
		{
			function init():Boolean
			{
				var columns:Array = getLinkableDescendants(WeaveAPI.globalHashMap, ReferencedColumn)
					.filter(function(rc:ReferencedColumn, i:*, a:*):Boolean {
						return rc.getDataSource() == null && rc.metadata.getSessionState() == null;
					});
				if (columns.length)
				{
					// Request the nodes whether or not the source is currently busy
					// because requesting them may be what makes it busy.
					var input:Array = HierarchyUtils.getAllColumnReferenceDescendants(fileSource);
					if (!input.length || linkableObjectIsBusy(fileSource))
					{
						// busy? try later
						getCallbackCollection(fileSource).addGroupedCallback(null, init);
					}
					else
					{
						// not busy, so initialize now
						ColumnUtils.initSelectableAttributes(columns, input);
						// only initialize once
						getCallbackCollection(fileSource).removeCallback(init);
					}
					// return true if there are blank ReferencedColumns 
					return true;
				}
				return false;
			}
			return init();
		}
		
		public function SessionMenu()
		{
			super({
				shown: {or: [fn_adminMode, Weave.properties.enableSessionMenu]},
				label: lang("Session"),
				children: [
					{
						label: lang("Edit Session State"),
						click: SessionStateEditor.openDefaultEditor
					},
					TYPE_SEPARATOR,
					{
						label: lang("Import session history"),
						click: importSessionHistory
					},
					{
						label: lang("Export session history"),
						click: ExportSessionStateOptions.openExportPanel
					},
					TYPE_SEPARATOR,
					{
						label: function():String {
							var shown:Boolean = Weave.properties.enableSessionHistoryControls.value;
							return lang((shown ? "Hide" : "Show") + " session history controls");
						},
						click: Weave.properties.enableSessionHistoryControls
					},
					TYPE_SEPARATOR,
					{
						shown: Weave.properties.enableManagePlugins,
						label: lang("Manage plugins"),
						click: managePlugins
					},
					TYPE_SEPARATOR,
					{
						shown: JavaScript.available,
						label: lang("Restart Weave"),
						click: Weave.externalReload
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
						shown: Weave.properties.showCreateTemplateMenuItem,
						label: lang("Convert this session state into a template"),
						click: function():void {
							PopUpUtils.confirm(
								null,
								lang("Create template"),
								lang("This will reset all attribute selections, remove all data sources, and clear the history. "
									+ "The attributes will be re-populated when you load a file through the Data menu."),
								createTemplate,
								null,
								lang("Ok"),
								lang("Cancel")
							);
						}
					},
					TYPE_SEPARATOR,
					{
						shown: fn_adminService,
						label: lang("Save session state to server"),
						click: saveSessionStateToServer
					}
				]
			});
		}
	}
}
