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

package weave.utils
{
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.compiler.StandardLib;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.QKeyManager;

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
			if (!dataType && data is Vector.<Number>)
				dataType = DataType.NUMBER;
			if (!dataType)
			{
				dataType = guessDataType(data);
				metadata[ColumnMetadata.DATA_TYPE] = dataType;
				proxyColumn.setMetadata(metadata);
			}
			
			var keysVector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
			if (StandardLib.arrayIsType(keys, IQualifiedKey))
			{
				keysVector = Vector.<IQualifiedKey>(keys);
				asyncCallback();
			}
			else
			{
				keysVector = new Vector.<IQualifiedKey>();
				(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(proxyColumn, metadata[ColumnMetadata.KEY_TYPE], keys, asyncCallback, keysVector);
			}
			
			function asyncCallback():void
			{
				var newColumn:IAttributeColumn;
				if (dataType == DataType.NUMBER)
				{
					newColumn = new NumberColumn(metadata);
					(newColumn as NumberColumn).setRecords(keysVector, data);
				}
				else if (dataType == DataType.DATE)
				{
					newColumn = new DateColumn(metadata);
					(newColumn as DateColumn).setRecords(keysVector, Vector.<String>(data));
				}
				else
				{
					newColumn = new StringColumn(metadata);
					(newColumn as StringColumn).setRecords(keysVector, Vector.<String>(data));
				}
				proxyColumn.setInternalColumn(newColumn);
			}
		}
	}
}
