/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	import weavejs.api.core.ILinkableVariable;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableBoolean;
	import weavejs.core.LinkableCallbackScript;
	import weavejs.core.LinkableDynamicObject;
	import weavejs.core.LinkableFunction;
	import weavejs.core.LinkableHashMap;
	import weavejs.core.LinkableNumber;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableSynchronizer;
	import weavejs.core.LinkableVariable;
	import weavejs.core.LinkableWatcher;
	import weavejs.core.SessionStateLog;
	import weavejs.core.WeaveArchive;
	import weavejs.data.bin.AbstractBinningDefinition;
	import weavejs.data.bin.CategoryBinningDefinition;
	import weavejs.data.bin.CustomSplitBinningDefinition;
	import weavejs.data.bin.DynamicBinningDefinition;
	import weavejs.data.bin.EqualIntervalBinningDefinition;
	import weavejs.data.bin.ExplicitBinningDefinition;
	import weavejs.data.bin.NaturalJenksBinningDefinition;
	import weavejs.data.bin.NumberClassifier;
	import weavejs.data.bin.QuantileBinningDefinition;
	import weavejs.data.bin.SimpleBinningDefinition;
	import weavejs.data.bin.SingleValueClassifier;
	import weavejs.data.bin.StandardDeviationBinningDefinition;
	import weavejs.data.bin.StringClassifier;
	import weavejs.data.column.AbstractAttributeColumn;
	import weavejs.data.column.AlwaysDefinedColumn;
	import weavejs.data.column.BinnedColumn;
	import weavejs.data.column.CSVColumn;
	import weavejs.data.column.ColorColumn;
	import weavejs.data.column.ColumnDataTask;
	import weavejs.data.column.CombinedColumn;
	import weavejs.data.column.DateColumn;
	import weavejs.data.column.DynamicColumn;
	import weavejs.data.column.EquationColumn;
	import weavejs.data.column.ExtendedDynamicColumn;
	import weavejs.data.column.FilteredColumn;
	import weavejs.data.column.GeometryColumn;
	import weavejs.data.column.NormalizedColumn;
	import weavejs.data.column.NumberColumn;
	import weavejs.data.column.ProxyColumn;
	import weavejs.data.column.ReferencedColumn;
	import weavejs.data.column.SecondaryKeyNumColumn;
	import weavejs.data.column.SortedColumn;
	import weavejs.data.column.SortedIndexColumn;
	import weavejs.data.column.StringColumn;
	import weavejs.data.column.StringLookup;
	import weavejs.data.hierarchy.WeaveRootDataTreeNode;
	import weavejs.data.key.ColumnDataFilter;
	import weavejs.data.key.DynamicKeyFilter;
	import weavejs.data.key.DynamicKeySet;
	import weavejs.data.key.FilteredKeySet;
	import weavejs.data.key.KeyFilter;
	import weavejs.data.key.KeySet;
	import weavejs.data.key.KeySetCallbackInterface;
	import weavejs.data.key.KeySetUnion;
	import weavejs.data.key.SortedKeySet;
	import weavejs.data.source.CSVDataSource;
	import weavejs.data.source.ForeignDataMappingTransform;
	import weavejs.data.source.GeoJSONDataSource;
	import weavejs.data.source.WeaveDataSource;
	import weavejs.geom.ZoomBounds;
	import weavejs.util.DebugUtils;
	import weavejs.util.JS;
	
	public class WeaveTest
	{
		private static const dependencies:Array = [
			ILinkableVariable,
			LinkableNumber,LinkableString,LinkableBoolean,LinkableVariable,
			LinkableHashMap,LinkableDynamicObject,LinkableWatcher,
			LinkableCallbackScript,LinkableSynchronizer,LinkableFunction,
			
			ColumnDataFilter,
			DynamicKeyFilter,
			DynamicKeySet,
			FilteredKeySet,
			KeyFilter,
			KeySet,
			KeySetCallbackInterface,
			KeySetUnion,
			SortedKeySet,
			
			AbstractBinningDefinition,
			CategoryBinningDefinition,
			CustomSplitBinningDefinition,
			DynamicBinningDefinition,
			EqualIntervalBinningDefinition,
			ExplicitBinningDefinition,
			NaturalJenksBinningDefinition,
			NumberClassifier,
			QuantileBinningDefinition,
			SimpleBinningDefinition,
			SingleValueClassifier,
			StandardDeviationBinningDefinition,
			StringClassifier,
			
			AbstractAttributeColumn,
			AlwaysDefinedColumn,
			BinnedColumn,
			ColorColumn,
			ColumnDataTask,
			CombinedColumn,
			CSVColumn,
			DateColumn,
			DynamicColumn,
			EquationColumn,
			ExtendedDynamicColumn,
			FilteredColumn,
			GeometryColumn,
			NormalizedColumn,
			NumberColumn,
			ProxyColumn,
			ReferencedColumn,
			SecondaryKeyNumColumn,
			SortedColumn,
			SortedIndexColumn,
			StringColumn,
			StringLookup,
			GeoJSONDataSource,
			WeaveDataSource,
			ForeignDataMappingTransform,
			
			ZoomBounds,
			WeaveArchive,
			WeaveRootDataTreeNode,
			
			null
		];
		
		public static function test(weave:Weave):void
		{
			SessionStateLog.debug = true;
			
			var lv:LinkableString = weave.root.requestObject('ls', LinkableString, false);
			lv.addImmediateCallback(weave, function():void { JS.log('immediate', lv.state); }, true);
			lv.addGroupedCallback(weave, function():void { JS.log('grouped', lv.state); }, true);
			lv.state = 'hello';
			lv.state = 'hello';
			weave.path('ls').state('hi').addCallback(null, function():void { JS.log(this+'', this.getState()); });
			lv.state = 'world';
			weave.path('script')
				.request('LinkableCallbackScript')
				.state('script', 'console.log(Weave.className(this), this.get("ldo").target.value, Weave.getState(this));')
				.push('variables', 'ldo')
					.request('LinkableDynamicObject')
					.state(['ls']);
			lv.state = '2';
			lv.state = 2;
			lv.state = '3';
			weave.path('ls2').request('LinkableString');
			weave.path('sync')
				.request('LinkableSynchronizer')
				.state('primaryPath', ['ls'])
				.state('primaryTransform', 'state + "_transformed"')
				.state('secondaryPath', ['ls2'])
				.call(function():void { JS.log(this.weave.path('ls2').getState()) });
			var print:Function = function():void {
				JS.log("column", this.getMetadata("title"));
				for each (var key:IQualifiedKey in this.keys)
					JS.log(key, this.getValueFromKey(key), this.getValueFromKey(key, Number), this.getValueFromKey(key, String));
			};
			weave.path('csv').request(CSVDataSource)
				.state('csvData', [['a', 'b'], [1, "one"], [2, "two"]])
				.addCallback(null, function():void {
					JS.log(this+"");
					var csv:CSVDataSource = this.getObject() as CSVDataSource;
					var ids:Array = csv.getColumnIds();
					for each (var id:* in ids)
					{
						var col:IAttributeColumn = csv.getColumnById(id);
						col.addGroupedCallback(col, print, true);
					}
				});
		}
	}
}
