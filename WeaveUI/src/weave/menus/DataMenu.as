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
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.Weave;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_File;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IDataSource_Transform;
	import weave.api.data.IQualifiedKey;
	import weave.api.reportError;
	import weave.api.ui.ISelectableAttributes;
	import weave.compiler.StandardLib;
	import weave.core.ClassUtils;
	import weave.data.AttributeColumns.CSVColumn;
	import weave.editors.managers.AddDataSourcePanel;
	import weave.editors.managers.DataSourceManager;
	import weave.services.addAsyncResponder;
	import weave.services.beans.KMeansClusteringResult;
	import weave.ui.AlertTextBox;
	import weave.ui.AttributeSelectorPanel;
	import weave.ui.DraggablePanel;
	import weave.ui.EquationEditor;
	import weave.utils.ColumnUtils;

	public class DataMenu extends WeaveMenuItem
	{
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
				label: lang("Refresh all data sources"),
				click: function():void {
					var ghm:ILinkableHashMap = WeaveAPI.globalHashMap;
					var dataSources:Array = ghm.getObjects(IDataSource);
					for each (var dataSource:IDataSource in dataSources)
					{
						dataSource.hierarchyRefresh.triggerCallbacks();
						ghm.requestObjectCopy(ghm.getName(dataSource), dataSource);
					}
				},
				enabled: function():Boolean { return WeaveAPI.globalHashMap.getObjects(IDataSource).length > 0; }
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
				if (WeaveAPI.EditorManager.getEditorClass(item.data))
				{
					var adsp:AddDataSourcePanel = DraggablePanel.openStaticInstance(AddDataSourcePanel);
					adsp.dataSourceType = item.data as Class;
				}
				else
				{
					var dsm:DataSourceManager = DraggablePanel.openStaticInstance(DataSourceManager) as DataSourceManager;
					dsm.selectDataSource(WeaveAPI.globalHashMap.requestObject(null, item.data as Class, false));
				}
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
								var shown:* = Weave.properties.getMenuToggle(impl);
								if (!alwaysShow)
									shown = [shown, Weave.properties.enableManageDataSources];
								return {
									shown: shown,
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
		
		public static const kMeansClusteringItem:WeaveMenuItem = new WeaveMenuItem({
			dependency: WeaveAPI.globalHashMap.childListCallbacks,
			shown: [Weave.properties.showKMeansClustering],
			label: lang("K-means clustering"),
			children: function():Array {
				return WeaveAPI.globalHashMap.getObjects(ISelectableAttributes)
					.map(function(isa:ISelectableAttributes, i:int, a:Array):Object {
						return {
							label: WeaveAPI.globalHashMap.getName(isa),
							click: doKMeans,
							data: isa
						};
					});
			}
		});
		private static function doKMeans(item:WeaveMenuItem):void
		{
			AlertTextBox.show(
				'K-means Clustering',
				'Please specify the number of clusters.',
				'4',
				null,
				function(userInput:String):void {
					var numberOfClusters:int = StandardLib.asNumber(userInput);
					var isa:ISelectableAttributes = item.data as ISelectableAttributes;
					var cols:Array = ColumnUtils.getNonWrapperColumnsFromSelectableAttributes(isa.getSelectableAttributes());
					cols = cols.filter(function(col:IAttributeColumn, i:int, a:Array):Boolean {
						return col.getMetadata(ColumnMetadata.DATA_TYPE) == DataType.NUMBER;
					});
					var inputValues:Array = ColumnUtils.joinColumns(cols, Number);
					var keys:Array = inputValues.shift();
					addAsyncResponder(
						Weave.properties.getRService().KMeansClustering(inputValues, false, numberOfClusters, 1000),
						function(event:ResultEvent, keys:Array):void {
							var result:KMeansClusteringResult = new KMeansClusteringResult(event.result as Array, keys);
							var rows:Array = keys.map(function(key:IQualifiedKey, i:int, a:Array):Array {
								return [key.localName, result.clusterVector[i]];
							});
							var name:String = WeaveAPI.globalHashMap.generateUniqueName('Clusters');
							var csvColumn:CSVColumn = WeaveAPI.globalHashMap.requestObject(name, CSVColumn, false);
							csvColumn.data.setSessionState(rows);
							csvColumn.title.value = name;
							csvColumn.keyType.value = (keys[0] as IQualifiedKey).keyType;
							weaveTrace(lang('The "{0}" column was generated.', name));
						},
						function(event:FaultEvent, keys:Array):void {
							reportError(event);
						},
						keys
					);
				}
			);
		}
		
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
						equationColumnItem,
						WeaveMenuItem.TYPE_SEPARATOR,
						kMeansClusteringItem
					]);
				}
			});
		}
	}
}
