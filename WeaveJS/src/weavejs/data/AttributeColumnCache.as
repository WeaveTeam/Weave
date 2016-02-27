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

package weavejs.data
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IAttributeColumnCache;
	import weavejs.api.data.IBaseColumn;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.data.column.DateColumn;
	import weavejs.data.column.GeometryColumn;
	import weavejs.data.column.NumberColumn;
	import weavejs.data.column.StringColumn;
	import weavejs.data.key.QKeyManager;
	import weavejs.data.source.CachedDataSource;
	import weavejs.geom.GeneralizedGeometry;
	import weavejs.util.Dictionary2D;
	import weavejs.util.JS;
	import weavejs.util.WeavePromise;
	
	public class AttributeColumnCache implements IAttributeColumnCache
	{
		public function getColumn(dataSource:IDataSource, metadata:Object):IAttributeColumn
		{
			// null means no column
			if (dataSource == null || metadata == null)
				return null;

			// Get the column pointer associated with the hash value.
			var hashCode:String = Weave.stringify(metadata);
			var column:IAttributeColumn = d2d_dataSource_metadataHash_column.get(dataSource, hashCode);
			if (!column)
			{
				// if this is the first time we've seen this data source, add dispose callback
				if (!d2d_dataSource_metadataHash_column.map.has(dataSource))
					Weave.getCallbacks(dataSource).addDisposeCallback(this, function():void {
						this.d2d_dataSource_metadataHash_column.map['delete'](dataSource);
					});
				
				// If no column is associated with this hash value, request the
				// column from its data source and save the column pointer.
				column = dataSource.getAttributeColumn(metadata);
				d2d_dataSource_metadataHash_column.set(dataSource, hashCode, column);
			}
			return column;
		}
		
		private var d2d_dataSource_metadataHash_column:Dictionary2D = new Dictionary2D();
		
		// TEMPORARY SOLUTION for WeaveArchive to access this cache data
		public const map_root_saveCache:Object = new JS.WeakMap();
		
		/**
		 * Creates a cache dump and modifies the session state so data sources are non-functional.
		 * @return A WeavePromise that returns a cache dump that can later be passed to restoreCache();
		 */
		public function convertToCachedDataSources(root:ILinkableHashMap):WeavePromise
		{
			var promise:WeavePromise = new WeavePromise(root).setResult(root);
			var dispose:Function = function(_:*):void { promise.dispose(); };
			var promiseThen:WeavePromise = promise
				.then(function(root:ILinkableHashMap):ILinkableHashMap {
					// request data from every column
					var column:IAttributeColumn;
					var columns:Array = Weave.getDescendants(root, IAttributeColumn);
					for each (column in columns)
					{
						// simply requesting the keys will cause the data to be requested
						if (column.keys.length)
							column.getValueFromKey(column.keys[0]);
						// wait for the column to finish any async tasks
						promise.depend(column);
					}
					return root;
				})
				.then(_convertToCachedDataSources);
			promiseThen.then(dispose, dispose);
			return promiseThen;
		}
		
		private function _convertToCachedDataSources(root:ILinkableHashMap):Array
		{
			//cache data from AttributeColumnCache
			var output:Array = [];
			var dataSource:*;
			var dataSources:Array = d2d_dataSource_metadataHash_column.primaryKeys();
			for each (dataSource in dataSources)
			{
				var dataSourceName:String = root.getName(dataSource);
				
				// skip disposed data sources and global columns (EquationColumn, CSVColumn)
				if (!dataSourceName)
					continue;
				
				var metadataHashes:Array = d2d_dataSource_metadataHash_column.secondaryKeys(dataSource);
				for each (var metadataHash:String in metadataHashes)
				{
					var column:IAttributeColumn = d2d_dataSource_metadataHash_column.get(dataSource, metadataHash);
					if (!column || Weave.wasDisposed(column))
						continue;
					var metadata:Object = ColumnMetadata.getAllMetadata(column);
					var dataType:String = column.getMetadata(ColumnMetadata.DATA_TYPE);
					var keys:Array = [];
					var data:Array = [];
					for each (var key:IQualifiedKey in column.keys)
					{
						var values:* = column.getValueFromKey(key, Array);
						// special case if column misbehaves and does not actually return an array when one is requested (not sure if this occurs)
						if (values != null && !(values is Array))
							values = [values];
						for each (var value:* in values)
						{
							if (dataType == DataType.GEOMETRY)
							{
								keys.push(key.localName);
								data.push((value as GeneralizedGeometry).toGeoJson());
							}
							else
							{
								keys.push(key.localName);
								data.push(value);
							}
						}
					}
					
					// output a set of arguments to addToColumnCache()
					output.push([dataSourceName, metadataHash, metadata, keys, data]);
				}
			}
			
			// stub out data sources
			dataSources = root.getObjects(IDataSource);
			for each (dataSource in dataSources)
			{
				if (dataSource.hasOwnProperty('NO_CACHE_HACK') || dataSource is CachedDataSource)
					continue;
				var type:String = Weave.className(dataSource);
				var state:Object = Weave.getState(dataSource);
				var cds:CachedDataSource = root.requestObject(root.getName(dataSource), CachedDataSource, false);
				cds.type.value = type;
				cds.state.state = state;
			}
			
			// repopulate cache for newly created data sources
			restoreCache(root, output);
			
			// TEMPORARY SOLUTION
			map_root_saveCache.set(root, output);
			
			return output;
		}
		
		/**
		 * Restores the cache from a dump created by convertToLocalDataSources().
		 * @param cacheData The cache dump.
		 */
		public function restoreCache(root:ILinkableHashMap, cacheData:Object):void
		{
			map_root_saveCache.set(root, cacheData);
			for each (var args:Array in cacheData)
				addToColumnCache.apply(this, [root].concat(args));
		}
		
		private function addToColumnCache(root:ILinkableHashMap, dataSourceName:String, metadataHash:String, metadata:Object, keyStrings:Array, data:Array):void
		{
			// create the column object
			var dataSource:IDataSource = root.getObject(dataSourceName) as IDataSource;
			if (!dataSource)
			{
				if (dataSourceName)
					JS.error("Data source not found: " + dataSourceName);
				return;
			}
			
			var column:IBaseColumn;
			var keyType:String = metadata[ColumnMetadata.KEY_TYPE];
			var dataType:String = metadata[ColumnMetadata.DATA_TYPE];
			
			if (dataType == DataType.GEOMETRY)
				column = Weave.disposableChild(dataSource, column = new GeometryColumn(metadata));
			else if (dataType == DataType.DATE)
				column = Weave.disposableChild(dataSource, column = new DateColumn(metadata));
			else if (dataType == DataType.NUMBER)
				column = Weave.disposableChild(dataSource, column = new NumberColumn(metadata));
			else // string
				column = Weave.disposableChild(dataSource, column = new StringColumn(metadata));
			
			(WeaveAPI.QKeyManager as QKeyManager)
				.getQKeysPromise(column, keyType, keyStrings)
				.then(function(keys:Array):void {
					if (column is GeometryColumn)
					{
						var geomKeys:Array = [];
						var geoms:Array = [];
						for (var i:int = 0; i < data.length; i++)
						{
							var geomsFromGeoJson:Array = GeneralizedGeometry.fromGeoJson(data[i]);
							for each (var geom:GeneralizedGeometry in geomsFromGeoJson)
							{
								geomKeys.push(keys[i]);
								geoms.push(geom);
							}
						}
						keys = geomKeys;
						data = geoms;
					}
					column.setRecords(keys, data);
				});
			
			// insert into cache
			d2d_dataSource_metadataHash_column.set(dataSource, metadataHash, column);
		}
		
		/**
		 * Restores a session state to what it was before calling convertToCachedDataSources().
		 */
		public function restoreFromCachedDataSources(root:ILinkableHashMap):void
		{
			for each (var cds:CachedDataSource in root.getObjects(CachedDataSource))
			{
				d2d_dataSource_metadataHash_column.removeAllPrimary(cds);
				cds.hierarchyRefresh.triggerCallbacks();
			}
		}
	}
}
