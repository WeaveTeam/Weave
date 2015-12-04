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
	
	import flash.utils.Dictionary;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.getLinkableDescendants;
	import weave.api.getSessionState;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.compiler.Compiler;
	import weave.core.ClassUtils;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.DataSources.CachedDataSource;
	import weave.primitives.Dictionary2D;
	import weave.primitives.GeneralizedGeometry;
	import weave.utils.WeakReference;
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
			var weakRef:WeakReference = d2d_dataSource_metadataHash.get(dataSource, hashCode) as WeakReference;
			if (weakRef != null && weakRef.value != null)
			{
				if (WeaveAPI.SessionManager.objectWasDisposed(weakRef.value))
					d2d_dataSource_metadataHash.remove(dataSource, hashCode);
				else
					return weakRef.value as IAttributeColumn;
			}
			
			// If no column is associated with this hash value, request the
			// column from its data source and save the column pointer.
			var column:IAttributeColumn = dataSource.getAttributeColumn(metadata);
			d2d_dataSource_metadataHash.set(dataSource, hashCode, new WeakReference(column));

			return column;
		}
		
		private const d2d_dataSource_metadataHash:Dictionary2D = new Dictionary2D(true, true);
		
		/**
		 * Creates a cache dump and modifies the session state so data sources are non-functional.
		 * @return A WeavePromise that returns a cache dump that can later be passed to restoreCache();
		 */
		public function convertToCachedDataSources():WeavePromise
		{
			var promise:WeavePromise = new WeavePromise(WeaveAPI.globalHashMap);
			
			// request data from every column
			var column:IAttributeColumn;
			for each (column in getLinkableDescendants(WeaveAPI.globalHashMap, IAttributeColumn))
			{
				// simply requesting the keys will cause the data to be requested
				if (column.keys.length)
					column.getValueFromKey(column.keys[0]);
				// wait for the column to finish any async tasks
				promise.depend(column);
			}
			promise.setResult(null);
			return promise.then(_convertToCachedDataSources);
		}
		
		private function _convertToCachedDataSources(promiseResult:*):Array
		{
			//cache data from AttributeColumnCache
			var output:Array = [];
			var cache:Dictionary = d2d_dataSource_metadataHash.dictionary;
			var dataSource:*;
			for (dataSource in cache)
			{
				// skip global columns (EquationColumn, CSVColumn)
				if (!dataSource)
					continue;
				
				var dataSourceName:String = WeaveAPI.globalHashMap.getName(dataSource);
				for (var metadataHash:String in cache[dataSource])
				{
					var column:IAttributeColumn = (cache[dataSource][metadataHash] as WeakReference).value as IAttributeColumn;
					var metadata:Object = ColumnMetadata.getAllMetadata(column);
					var dataType:String = column.getMetadata(ColumnMetadata.DATA_TYPE);
					var keys:Array = [];
					var data:Array = [];
					for each (var key:IQualifiedKey in column.keys)
					{
						for each (var value:* in column.getValueFromKey(key, Array))
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
			for each (dataSource in WeaveAPI.globalHashMap.getObjects(IDataSource))
			{
				var type:String = getQualifiedClassName(dataSource);
				var state:Object = getSessionState(dataSource);
				var cds:CachedDataSource = WeaveAPI.globalHashMap.requestObject(WeaveAPI.globalHashMap.getName(dataSource), CachedDataSource, false);
				cds.type.value = type;
				cds.state.state = state;
			}
			
			return output;
		}
		
		/**
		 * Restores a session state to what it was before calling convertToCachedDataSources().
		 */
		public function restoreFromCachedDataSources():void
		{
			for each (var cds:CachedDataSource in WeaveAPI.globalHashMap.getObjects(CachedDataSource))
			{
				d2d_dataSource_metadataHash.removeAllPrimary(cds);
				var name:String = WeaveAPI.globalHashMap.getName(cds);
				var classDef:Class = ClassUtils.getClassDefinition(cds.type.value);
				var state:Object = cds.state.state;
				var dataSource:IDataSource = WeaveAPI.globalHashMap.requestObject(name, classDef, false);
				setSessionState(dataSource, state);
			}
		}
		
		/**
		 * Restores the cache from a dump created by convertToLocalDataSources().
		 * @param cacheData The cache dump.
		 */
		public function restoreCache(cacheData:Object):void
		{
			for each (var args:Array in cacheData)
				addToColumnCache.apply(this, args);
		}
		
		private function addToColumnCache(dataSourceName:String, metadataHash:String, metadata:Object, keyStrings:Array, data:Array):void
		{
			// create the column object
			var dataSource:IDataSource = WeaveAPI.globalHashMap.getObject(dataSourceName) as IDataSource;
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
							for each (var geom:GeneralizedGeometry in GeneralizedGeometry.fromGeoJson(data[i]))
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
			d2d_dataSource_metadataHash.set(dataSource, metadataHash, column);
		}
	}
}
