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

package weave.data
{
	import avmplus.getQualifiedClassName;
	
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.getSessionState;
	import weave.api.objectWasDisposed;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.compiler.Compiler;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.DataSources.CachedDataSource;
	import weave.primitives.Dictionary2D;
	import weave.primitives.GeneralizedGeometry;
	import weave.utils.WeavePromise;
	
	/**
	 * @inheritDoc
	 */
	public class AttributeColumnCache implements IAttributeColumnCache
	{
		/**
		 * @inheritDoc
		 */
		public function getColumn(dataSource:IDataSource, metadata:Object):IAttributeColumn
		{
			// null means no column
			if (dataSource == null || metadata == null)
				return null;

			// Get the column pointer associated with the hash value.
			var hashCode:String = Compiler.stringify(metadata);
			var column:IAttributeColumn = d2d_dataSource_metadataHash_column.get(dataSource, hashCode);
			if (!column)
			{
				// if this is the first time we've seen this data source, add dispose callback
				if (!d2d_dataSource_metadataHash_column.dictionary[dataSource])
					getCallbackCollection(dataSource).addDisposeCallback(this, function():void {
						delete this.d2d_dataSource_metadataHash_column.dictionary[dataSource];
					});
				
				// If no column is associated with this hash value, request the
				// column from its data source and save the column pointer.
				column = dataSource.getAttributeColumn(metadata);
				d2d_dataSource_metadataHash_column.set(dataSource, hashCode, column);
			}
			return column;
		}
		
		private const d2d_dataSource_metadataHash_column:Dictionary2D = new Dictionary2D();
		
		// TEMPORARY SOLUTION for WeaveArchive to access this cache data
		public var saveCache:Object = null;
		
		/**
		 * Creates a cache dump and modifies the session state so data sources are non-functional.
		 * @return A WeavePromise that returns a cache dump that can later be passed to restoreCache();
		 */
		public function convertToCachedDataSources():WeavePromise
		{
			var promise:WeavePromise = new WeavePromise(WeaveAPI.globalHashMap);
			promise.setResult(null);
			var dispose:Function = function(_:*):void { promise.dispose(); };
			return promise
				.then(function(_:*):* {
					// request data from every column
					var column:IAttributeColumn;
					var columns:Array = getLinkableDescendants(WeaveAPI.globalHashMap, IAttributeColumn);
					for each (column in columns)
					{
						// simply requesting the keys will cause the data to be requested
						if (column.keys.length)
							column.getValueFromKey(column.keys[0]);
						// wait for the column to finish any async tasks
						promise.depend(column);
					}
				})
				.then(_convertToCachedDataSources, reportError)
				.then(dispose, dispose);
		}
		
		private function _convertToCachedDataSources(promiseResult:*):Array
		{
			//cache data from AttributeColumnCache
			var output:Array = [];
			var dataSource:*;
			var dataSources:Array = d2d_dataSource_metadataHash_column.primaryKeys();
			for each (dataSource in dataSources)
			{
				var dataSourceName:String = WeaveAPI.globalHashMap.getName(dataSource);
				
				// skip disposed data sources and global columns (EquationColumn, CSVColumn)
				if (!dataSourceName)
					continue;
				
				var metadataHashes:Array = d2d_dataSource_metadataHash_column.secondaryKeys(dataSource);
				for each (var metadataHash:String in metadataHashes)
				{
					var column:IAttributeColumn = d2d_dataSource_metadataHash_column.get(dataSource, metadataHash);
					if (!column || objectWasDisposed(column))
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
			dataSources = WeaveAPI.globalHashMap.getObjects(IDataSource);
			for each (dataSource in dataSources)
			{
				if (dataSource.hasOwnProperty('NO_CACHE_HACK'))
					continue;
				var type:String = getQualifiedClassName(dataSource);
				var state:Object = getSessionState(dataSource);
				var cds:CachedDataSource = WeaveAPI.globalHashMap.requestObject(WeaveAPI.globalHashMap.getName(dataSource), CachedDataSource, false);
				cds.type.value = type;
				cds.state.state = state;
			}
			
			// repopulate cache for newly created data sources
			restoreCache(output);
			
			// TEMPORARY SOLUTION
			saveCache = output;
			
			return output;
		}
		
		/**
		 * Restores the cache from a dump created by convertToLocalDataSources().
		 * @param cacheData The cache dump.
		 */
		public function restoreCache(cacheData:Object):void
		{
			saveCache = cacheData;
			for each (var args:Array in cacheData)
				addToColumnCache.apply(this, args);
		}
		
		private function addToColumnCache(dataSourceName:String, metadataHash:String, metadata:Object, keyStrings:Array, data:Array):void
		{
			// create the column object
			var dataSource:IDataSource = WeaveAPI.globalHashMap.getObject(dataSourceName) as IDataSource;
			if (!dataSource)
			{
				if (dataSourceName)
					reportError("Data source not found: " + dataSourceName);
				return;
			}
			var column:IAttributeColumn;
			var keyType:String = metadata[ColumnMetadata.KEY_TYPE];
			var dataType:String = metadata[ColumnMetadata.DATA_TYPE];
			if (dataType == DataType.NUMBER)
			{
				var nc:NumberColumn = registerLinkableChild(dataSource, column = new NumberColumn(metadata));
				(WeaveAPI.QKeyManager as QKeyManager)
					.getQKeysPromise(column, keyType, keyStrings)
					.then(function(keys:Vector.<IQualifiedKey>):void {
						nc.setRecords(keys, Vector.<Number>(data));
					});
			}
			else if (dataType == DataType.GEOMETRY)
			{
				var gc:GeometryColumn = registerLinkableChild(dataSource, column = new GeometryColumn(metadata));
				(WeaveAPI.QKeyManager as QKeyManager)
					.getQKeysPromise(column, keyType, keyStrings)
					.then(function(keys:Vector.<IQualifiedKey>):void {
						var geomKeys:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
						var geoms:Vector.<GeneralizedGeometry> = new Vector.<GeneralizedGeometry>();
						for (var i:int = 0; i < data.length; i++)
						{
							var geomsFromGeoJson:Array = GeneralizedGeometry.fromGeoJson(data[i]);
							for each (var geom:GeneralizedGeometry in geomsFromGeoJson)
							{
								geomKeys.push(keys[i]);
								geoms.push(geom);
							}
						}
						gc.setGeometries(geomKeys, geoms);
					});
			}
			else if (dataType == DataType.DATE)
			{
				var dc:DateColumn = registerLinkableChild(dataSource, column = new DateColumn(metadata));
				(WeaveAPI.QKeyManager as QKeyManager)
					.getQKeysPromise(column, keyType, keyStrings)
					.then(function(keys:Vector.<IQualifiedKey>):void {
						dc.setRecords(keys, Vector.<String>(data));
					});
			}
			else // string
			{
				var sc:StringColumn = registerLinkableChild(dataSource, column = new StringColumn(metadata));
				(WeaveAPI.QKeyManager as QKeyManager)
					.getQKeysPromise(column, keyType, keyStrings)
					.then(function(keys:Vector.<IQualifiedKey>):void {
						sc.setRecords(keys, Vector.<String>(data));
					});
			}
			
			// insert into cache
			d2d_dataSource_metadataHash_column.set(dataSource, metadataHash, column);
		}
	}
}
