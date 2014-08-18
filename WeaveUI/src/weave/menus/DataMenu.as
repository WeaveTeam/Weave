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
	
	import weave.Weave;
	import weave.api.data.IDataSource;
	import weave.api.ui.IObjectWithSelectableAttributes;
	import weave.editors.managers.AddDataSourcePanel;
	import weave.editors.managers.DataSourceManager;
	import weave.ui.AttributeSelectorPanel;
	import weave.ui.DraggablePanel;
	import weave.ui.NewUserWizard;
	import weave.ui.WizardPanel;

	public class DataMenu extends WeaveMenuItem
	{
		// TODO: make it so we are not dependent on VisApplication
		private static function exportCSV():void
		{
			WeaveAPI.topLevelApplication['visApp']['exportCSV']();
		}
		
		public static const staticItems:Array = createItems(
			{
				shown: Weave.properties.enableLoadMyData,
				label: lang("Load my data"),
				click: function():void { WizardPanel.createWizard(WeaveAPI.topLevelApplication as DisplayObject, new NewUserWizard()); }
			},{
				shown: Weave.properties.enableBrowseData,
				label: lang("Browse Data"),
				click: AttributeSelectorPanel.open
			},{
				shown: Weave.properties.enableManageDataSources,
				label: lang("Manage or browse data"),
				click: function():void { DraggablePanel.openStaticInstance(DataSourceManager); }
			},{
				shown: Weave.properties.enableRefreshHierarchies,
				label: lang("Refresh all data source hierarchies"),
				click: function():void {
					var sources:Array = WeaveAPI.globalHashMap.getObjects(IDataSource);
					for each (var source:IDataSource in sources)
					source.refreshHierarchy();
				},
				enabled: function():Boolean { return WeaveAPI.globalHashMap.getObjects(IDataSource).length > 0; }
			},{
				shown: Weave.properties.enableExportCSV,
				label: lang("Export CSV from all visualizations"),
				click: exportCSV,
				enabled: function():Boolean { return WeaveAPI.globalHashMap.getObjects(IObjectWithSelectableAttributes).length > 0; }
			}
		);
		
		public static function getDynamicItems(labelFormat:String = null):Array
		{
			function getLabel(item:WeaveMenuItem):String
			{
				var displayName:String = WeaveAPI.ClassRegistry.getDisplayName(item.data as Class);
				if (labelFormat)
					return lang(labelFormat, displayName);
				return displayName;
			}
			function onClick(item:WeaveMenuItem):void
			{
				var adsp:AddDataSourcePanel = DraggablePanel.openStaticInstance(AddDataSourcePanel);
				adsp.dataSourceType = item.data as Class;
			}
			return createItems(
				WeaveAPI.ClassRegistry.getImplementations(IDataSource).map(
					function(impl:Class, ..._):* {
						return {
							shown: Weave.properties.enableManageDataSources,
							label: getLabel,
							click: onClick,
							data: impl
						};
					}
				)
			);
		}
		
		public function DataMenu()
		{
			super({
				shown: Weave.properties.enableDataMenu,
				label: lang("Data"),
				children: function():Array
				{
					return createItems(
						staticItems,
						TYPE_SEPARATOR,
						getDynamicItems("Add {0}")
					);
				}
			});
		}
	}
}
