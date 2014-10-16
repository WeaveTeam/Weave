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
	import weave.Weave;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_File;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IDataSource_Transform;
	import weave.api.ui.ISelectableAttributes;
	import weave.core.ClassUtils;
	import weave.editors.managers.AddDataSourcePanel;
	import weave.editors.managers.DataSourceManager;
	import weave.ui.AttributeSelectorPanel;
	import weave.ui.DraggablePanel;
	import weave.ui.EquationEditor;

	public class DataMenu extends WeaveMenuItem
	{
		// TODO: make it so we are not dependent on VisApplication
		private static function exportCSV():void
		{
			WeaveAPI.topLevelApplication['visApp']['exportCSV']();
		}
		
		public static const staticItems:Array = createItems([
			{
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
				enabled: function():Boolean { return WeaveAPI.globalHashMap.getObjects(ISelectableAttributes).length > 0; }
			}
		]);
		
		public static function getDynamicItems(labelFormat:String = null, alwaysShow:Boolean = false):Array
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
				ClassUtils.partitionClassList(
					WeaveAPI.ClassRegistry.getImplementations(IDataSource),
					IDataSource_File,
					IDataSource_Service,
					IDataSource_Transform
				).map(
					function(group:Array, i:*, a:*):Array {
						return group.map(
							function(impl:Class, i:*, a:*):Object {
								return {
									shown: {or: [alwaysShow, Weave.properties.enableManageDataSources]},
									label: getLabel,
									click: onClick,
									data: impl
								};
							}
						)
					}
				)
			);
		}
		
		public static const equationColumnItem:WeaveMenuItem = new WeaveMenuItem({
			shown: [Weave.properties.showEquationEditor],
			label: lang("Equation Column Editor"),
			click: function():void { DraggablePanel.openStaticInstance(EquationEditor); }
		});
		
		public function DataMenu()
		{
			super({
				shown: Weave.properties.enableDataMenu,
				label: lang("Data"),
				children: function():Array
				{
					return createItems([
						staticItems,
						getDynamicItems("+ {0}"),
						equationColumnItem
					]);
				}
			});
		}
	}
}
