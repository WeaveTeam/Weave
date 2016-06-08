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
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.data.IDataSource;
	import weavejs.data.column.DateColumn;
	import weavejs.data.column.NumberColumn;
	import weavejs.data.column.ProxyColumn;
	import weavejs.data.column.StringColumn;
	import weavejs.data.key.QKeyManager;
	import weavejs.util.StandardLib;
	import weavejs.util.JS;
	
	public class DataSourceUtils
	{
		private static const numberRegex:RegExp = /^(0|0?\\.[0-9]+|[1-9][0-9]*(\\.[0-9]+)?)([eE][-+]?[0-9]+)?$/;
		
		public static function guessDataType(data:Array):String
		{
			var dateFormats:Array = DateColumn.detectDateFormats(data);
			if (dateFormats.length)
				return DataType.DATE;
			
			for each (var value:* in data)
			if (value != null && !(value is Number) && !numberRegex.test(value))
				return DataType.STRING;
			
			return DataType.NUMBER;
		}

		private static var _weakMap_dataSource_isLocal:Object = new JS.WeakMap();
		/**
		 * Determine whether a datasource that uses columns from other datasources that are remote.
		 * @param  dataSource The datasource to test.
		 * @return            True if a remote column is used by the datasource; false otherwise.
		 */
		public static function hasRemoteColumnDependencies(dataSource:IDataSource):Boolean
		{
			/* Possibly cache this and check for changes? */
			for each (var column:IAttributeColumn in Weave.getDescendants(dataSource, IAttributeColumn))
			{
				for each (var columnDataSource:IDataSource in ColumnUtils.getDataSources(column))
				{
					if (columnDataSource === dataSource) continue;
					var isLocal:Boolean;
					if (Weave.detectChange(_weakMap_dataSource_isLocal, columnDataSource))
					{
						isLocal = columnDataSource.isLocal;
						_weakMap_dataSource_isLocal.set(columnDataSource, isLocal);
					}
					else
					{
						isLocal = _weakMap_dataSource_isLocal.has(columnDataSource) ? 
							_weakMap_dataSource_isLocal.get(columnDataSource) : true;
					}

					if (!isLocal)
						return true;
				}
			}

			return false;
		}
		
		/**
		 * Fills a ProxyColumn with an appropriate internal column containing the given keys and data.
		 * @param proxyColumn A column, pre-filled with metadata
		 * @param keys An Array of either IQualifiedKeys or Strings
		 * @param data An Array of data values corresponding to the keys.
		 */
		public static function initColumn(proxyColumn:ProxyColumn, keys:Array, data:Array):void
		{
			var metadata:Object = proxyColumn.getProxyMetadata();
			var dataType:String = metadata[ColumnMetadata.DATA_TYPE];
			if (!dataType && StandardLib.getArrayType(data) === Number)
				dataType = DataType.NUMBER;
			if (!dataType)
			{
				dataType = guessDataType(data);
				metadata[ColumnMetadata.DATA_TYPE] = dataType;
				proxyColumn.setMetadata(metadata);
			}
			
			var qkeys:Array;
			if (StandardLib.arrayIsType(keys, IQualifiedKey))
			{
				qkeys = keys;
				asyncCallback();
			}
			else
			{
				qkeys = [];
				(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(proxyColumn, metadata[ColumnMetadata.KEY_TYPE], keys, asyncCallback, qkeys);
			}
			
			function asyncCallback():void
			{
				var newColumn:IAttributeColumn;
				if (dataType == DataType.NUMBER)
				{
					newColumn = new NumberColumn(metadata);
					(newColumn as NumberColumn).setRecords(qkeys, data);
				}
				else if (dataType == DataType.DATE)
				{
					newColumn = new DateColumn(metadata);
					(newColumn as DateColumn).setRecords(qkeys, data);
				}
				else
				{
					newColumn = new StringColumn(metadata);
					(newColumn as StringColumn).setRecords(qkeys, data);
				}
				proxyColumn.setInternalColumn(newColumn);
			}
		}
	}
}
