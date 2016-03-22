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
	import flash.events.Event;
	import flash.net.FileReference;
	
	import mx.controls.Alert;
	
	import weave.Weave;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.linkableObjectIsBusy;
	import weave.api.reportError;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_File;
	import weave.api.ui.ISelectableAttributes;
	import weave.data.AttributeColumnCache;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.DataSources.CachedDataSource;
	import weave.data.KeySets.KeySet;
	import weave.ui.ExportSessionStateOptions;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.PopUpUtils;

	public class FileMenu extends WeaveMenuItem
	{
		// TODO: make it so we are not dependent on VisApplication implementation
		public static function getSupportedFileTypes():Array
		{
			// TEMPORARY SOLUTION until we can register file type handlers in WeaveAPI
			return WeaveAPI.topLevelApplication['visApp']['getSupportedFileTypes']();
		}
		public static function loadFile(fileName:String, fileContent:Object):void
		{
			//WeaveAPI.topLevelApplication['visApp']['loadSessionState'](fileContent, fileName);
			WeaveAPI.topLevelApplication['visApp']['handleDraggedFile'](fileName, fileContent);
		}
		private function saveSessionStateToServer():void
		{
			WeaveAPI.topLevelApplication['visApp']['saveSessionStateToServer']();
		}
		private static function exportCSV():void
		{
			WeaveAPI.topLevelApplication['visApp']['exportCSV']();
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
		private function browseForFile():void
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
						loadFile(_weaveFileRef.name, _weaveFileRef.data);
					});
				}
				_weaveFileRef.browse(getSupportedFileTypes());
			}
			catch (e:Error)
			{
				reportError(e);
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
		
		public function FileMenu()
		{
			super({
				shown: {or: [fn_adminMode, Weave.properties.enableSessionMenu]},
				label: lang("File"),
				children: [
					{
						label: lang("Open a file..."),
						click: browseForFile
					},
					{
						label: lang("Save as..."),
						click: ExportSessionStateOptions.openExportPanel
					},
					TYPE_SEPARATOR,
					{
						shown: Weave.properties.enableExportCSV,
						label: lang("Export CSV"),
						click: exportCSV,
						enabled: function():Boolean { return WeaveAPI.globalHashMap.getObjects(ISelectableAttributes).length > 0; }
					},
					TYPE_SEPARATOR,
					{
						shown: Weave.properties.showCreateTemplateMenuItem,
						label: lang("Convert to template"),
						click: function():void {
							PopUpUtils.confirm(
								null,
								lang("Create template"),
								lang("This will reset all attribute selections, remove all data sources, and clear the history. "
									+ "The attributes will be re-populated when you load a data file."),
								createTemplate,
								null,
								lang("Ok"),
								lang("Cancel")
							);
						}
					},
					{
						enabled: function():Boolean {
							// only enable this item if there is at least one data source that is not cached
							for each (var ds:IDataSource in WeaveAPI.globalHashMap.getObjects(IDataSource))
								if (!(ds is CachedDataSource))
									return true;
							return false;
						},
						label: lang("Convert to cached data sources"),
						click: function():void {
							(WeaveAPI.AttributeColumnCache as AttributeColumnCache)
								.convertToCachedDataSources()
								.then(function(cache:Object):void {
									Alert.show("Column data has been cached. You can now save the .weave archive.");
								});
						}
					},
					TYPE_SEPARATOR,
					{
						shown: fn_adminService,
						label: lang("Save to server"),
						click: saveSessionStateToServer
					}
				]
			});
		}
	}
}
