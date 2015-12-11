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
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.api.copySessionState;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IKeySet;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.compiler.StandardLib;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.ExtendedDynamicColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.AttributeColumns.SecondaryKeyNumColumn;
	import weave.primitives.BLGNode;
	import weave.primitives.GeneralizedGeometry;
	
	/**
	 * This class contains static functions that access values from IAttributeColumn objects.
	 * 
	 * @author adufilie
	 */
	public class ColumnUtils
	{
		public static var debugKeyTypes:Boolean = false;
		
		/**
		 * This is a shortcut for column.getMetadata(ColumnMetadata.TITLE).
		 * @param column A column to get the title of.
		 * @return The title of the column.
		 */		
		public static function getTitle(column:IAttributeColumn):String
		{
			var title:String = column.getMetadata(ColumnMetadata.TITLE) || ProxyColumn.DATA_UNAVAILABLE;
			
			if (debugKeyTypes)
			{
				var keyType:String = column.getMetadata(ColumnMetadata.KEY_TYPE);
				if (keyType)
					title += " (Key type: " + keyType + ")";
				else
					title += " (No key type)";
			}

			return title;
		}
		
		/**
		 * Generates a label to use when displaying the column in a list.
		 * @param column
		 * @return The column title followed by its dataType and/or keyType metadata.
		 */		
		public static function getColumnListLabel(column:IAttributeColumn):String
		{
			var title:String = ColumnUtils.getTitle(column);
			var keyType:String = ColumnUtils.getKeyType(column);
			var dataType:String = ColumnUtils.getDataType(column);
			var projection:String = column.getMetadata(ColumnMetadata.PROJECTION);
			var dateFormat:String = column.getMetadata(ColumnMetadata.DATE_FORMAT);
			
			if (dataType == DataType.DATE && dateFormat)
				dataType = dataType + '; ' + dateFormat;
			if (dataType == DataType.GEOMETRY && projection)
				dataType = dataType + '; ' + projection;
			
			if (dataType && keyType)
				return StandardLib.substitute("{0} ({1} -> {2})", title, keyType, dataType);
			if (keyType)
				return StandardLib.substitute("{0} (Key Type: {1})", title, keyType);
			if (dataType)
				return StandardLib.substitute("{0} (Data Type: {1})", title, dataType);
			
			return title;
		}
		
		/**
		 * Temporary solution
		 * @param column
		 * @return 
		 */
		public static function getDataSources(column:IAttributeColumn):Array
		{
			var sources:Array = [];
			var name:String;
			var nameMap:Object = {};
			var cols:Array;
			if (column is ReferencedColumn)
				cols = [column];
			else
				cols = getLinkableDescendants(column, ReferencedColumn);
			for (var i:int = 0; i < cols.length; i++)
				sources.push((cols[i] as ReferencedColumn).getDataSource());
			return VectorUtils.union(sources);
		}

		/**
		 * This function gets the keyType of a column, either from the metadata or from the actual keys.
		 * @param column A column to get the keyType of.
		 * @return The keyType of the column.
		 */
		public static function getKeyType(column:IAttributeColumn):String
		{
			// first try getting the keyType from the metadata.
			var keyType:String = column.getMetadata(ColumnMetadata.KEY_TYPE);
			if (keyType == null)
			{
				// if metadata does not specify keyType, get it from the first key in the list of keys.
				var keys:Array = column.keys;
				if (keys.length > 0)
					keyType = (keys[0] as IQualifiedKey).keyType;
			}
			return keyType;
		}
		
		/**
		 * This function gets the dataType of a column from its metadata.
		 * @param column A column to get the dataType of.
		 * @return The dataType of the column.
		 */
		public static function getDataType(column:IAttributeColumn):String
		{
			return column.getMetadata(ColumnMetadata.DATA_TYPE);
		}
		
		/**
		 * This function will use an attribute column to convert a number to a string.
		 * @param column A column that may have a way to convert numeric values to string values.
		 * @param number A Number to convert to a String.
		 * @return A String representation of the number, or null if no specific string representation exists.
		 */
		public static function deriveStringFromNumber(column:IAttributeColumn, number:Number):String
		{
			var pc:IPrimitiveColumn = hack_findNonWrapperColumn(column) as IPrimitiveColumn;
			if (pc)
				return pc.deriveStringFromNumber(number);
			return null; // no specific string representation
		}
		
		public static function hack_findNonWrapperColumn(column:IAttributeColumn):IAttributeColumn
		{
			// try to find an internal IPrimitiveColumn
			while (column is IColumnWrapper)
				column = (column as IColumnWrapper).getInternalColumn();
			return column;
		}
		
		public static function hack_findInternalDynamicColumn(columnWrapper:IColumnWrapper):DynamicColumn
		{
			var columnWrapper:IColumnWrapper = columnWrapper as IColumnWrapper;
			if (columnWrapper)
			{
				// temporary solution - find internal dynamic column
				while (true)
				{
					if (columnWrapper.getInternalColumn() is DynamicColumn)
						columnWrapper = columnWrapper.getInternalColumn() as IColumnWrapper;
					else if (columnWrapper.getInternalColumn() is ExtendedDynamicColumn)
						columnWrapper = (columnWrapper.getInternalColumn() as ExtendedDynamicColumn).internalDynamicColumn;
					else
						break;
				}
				if (columnWrapper is ExtendedDynamicColumn)
					columnWrapper = (columnWrapper as ExtendedDynamicColumn).internalDynamicColumn;
			}
			return columnWrapper as DynamicColumn;
		}

		/**
		 * Gets an array of QKey objects from <code>column</code> which meet the criteria
		 * <code>min &lt;= getNumber(column, key) &lt;= max</code>, where key is a <code>QKey</code> 
		 * in <code>column</code>.
		 * @param min The minimum value for the keys
		 * @param max The maximum value for the keys
		 * @param inclusiveRange A boolean specifying whether the range includes the min and max values.
		 * Default value is <code>true</code>.
		 * @return An array QKey objects. 
		 */		
		public static function getQKeysInNumericRange(column:IAttributeColumn, min:Number, max:Number, inclusiveRange:Boolean = true):Array
		{
			var result:Array = [];
			var keys:Array = column.keys;
			for each (var qkey:IQualifiedKey in keys)
			{
				var number:Number = column.getValueFromKey(qkey, Number);
				var isInRange:Boolean = false;
				if (inclusiveRange)
					isInRange = min <= number && number <= max;
				else
					isInRange = min < number && number < max;
				
				if (isInRange)
					result.push(qkey);
			}
			
			return result;
		}
		
		[Deprecated(replacement="WeaveAPI.QKeyManager.convertToQKeys()")] public static function getQKeys(genericObjects:Array):Array
		{
			return WeaveAPI.QKeyManager.convertToQKeys(genericObjects);
		}
			
		/**
		 * Get the QKey corresponding to <code>object.keyType</code>
		 * and <code>object.localName</code>.
		 * 
		 * @param object An object with properties <code>keyType</code>
		 * and <code>localName</code>.
		 * @return An IQualifiedKey object. 
		 */		
		private static function getQKey(object:Object):IQualifiedKey
		{
			if (object is IQualifiedKey)
				return object as IQualifiedKey;
			return WeaveAPI.QKeyManager.getQKey(object.keyType, object.localName);
		}
		
		/**
		 * @param column A column to get a value from.
		 * @param key A key in the given column to get the value for.
		 * @return The Number corresponding to the given key.
		 */
		public static function getNumber(column:IAttributeColumn, key:Object):Number
		{
			var qkey:IQualifiedKey = getQKey(key);
			if (column != null)
				return column.getValueFromKey(qkey, Number);
			return NaN;
		}
		/**
		 * @param column A column to get a value from.
		 * @param key A key in the given column to get the value for.
		 * @return The String corresponding to the given key.
		 */
		public static function getString(column:IAttributeColumn, key:Object):String
		{
			var qkey:IQualifiedKey = getQKey(key);
			if (column != null)
				return column.getValueFromKey(qkey, String) as String;
			return '';
		}
		/**
		 * @param column A column to get a value from.
		 * @param key A key in the given column to get the value for.
		 * @return The Boolean corresponding to the given key.
		 */
		public static function getBoolean(column:IAttributeColumn, key:Object):Boolean
		{
			var qkey:IQualifiedKey = getQKey(key);
			if (column != null)
				return StandardLib.asBoolean( column.getValueFromKey(qkey, Number) );
			return false;
		}
		/**
		 * @param column A column to get a value from.
		 * @param key A key in the given column to get the value for.
		 * @return The Number corresponding to the given key, normalized to be between 0 and 1.
		 */
		[Deprecated(replacement="WeaveAPI.StatisticsCache.getColumnStatistics(column).getNorm(key)")]
		public static function getNorm(column:IAttributeColumn, key:Object):Number
		{
			var qkey:IQualifiedKey = getQKey(key);
			return WeaveAPI.StatisticsCache.getColumnStatistics(column).getNorm(qkey);
		}
		
		/**
		 * @param geometryColumn A GeometryColumn which contains the geometry objects for the key.
		 * @param key An object with <code>keyType</code> and <code>localName</code> properties.
		 * @return An array of arrays of arrays of Points.
		 * For example, 
		 * <code>result[0]</code> is type <code>Array of Array of Point</code>. <br>
		 * <code>result[0][0]</code> is type <code>Array of Point</code> <br>
		 * <code>result[0][0][0]</code> is a <code>Point</code>
		 */		
		public static function getGeometry(geometryColumn:IAttributeColumn, key:Object):Array
		{
			var qkey:IQualifiedKey = getQKey(key);
			var genGeoms:Array = geometryColumn.getValueFromKey(qkey, Array) as Array;
			
			if (genGeoms == null)
				return null;
			
			var result:Array = [];
			
			for (var iGenGeom:int; iGenGeom < genGeoms.length; ++iGenGeom)
			{
				var genGeom:GeneralizedGeometry = genGeoms[iGenGeom];
				var simplifiedGeom:Vector.<Vector.<BLGNode>> = genGeom.getSimplifiedGeometry();
				var newSimplifiedGeom:Array = [];			
				for (var iSimplifiedGeom:int; iSimplifiedGeom < simplifiedGeom.length; ++iSimplifiedGeom)
				{
					var nodeVector:Vector.<BLGNode> = simplifiedGeom[iSimplifiedGeom];
					var newNodeVector:Array = [];
					for (var iNode:int = 0; iNode < nodeVector.length; ++iNode)
					{
						var node:BLGNode = nodeVector[iNode];
						var point:Point = new Point(node.x, node.y);
						newNodeVector.push(point);
					}
					newSimplifiedGeom.push(newNodeVector);
				}
				result.push(newSimplifiedGeom);
			}
			
			return result;			
		}
		
		/**
		 * @param geometryColumn A column with metadata dataType="geometry"
		 * @param keys An Array of IQualifiedKeys
		 * @param minImportance No points with importance less than this value will be returned.
		 * @param visibleBounds If not null, this bounds will be used to remove unnecessary offscreen points.
		 * @return An Array of GeoJson Geometry objects corresponding to the keys.
		 */
		public static function getGeoJsonGeometries(geometryColumn:IAttributeColumn, keys:Array, minImportance:Number = 0, visibleBounds:IBounds2D = null):Array
		{
			var output:Array = new Array(keys.length);
			for (var i:int = 0; i < keys.length; i++)
			{
				var key:IQualifiedKey = keys[i];
				var genGeoms:Array = geometryColumn.getValueFromKey(key, Array) as Array;
				var geoJsonGeoms:Array = genGeoms.map(function(genGeom:GeneralizedGeometry, ..._):Object {
					return genGeom.toGeoJson(minImportance, visibleBounds);
				});
				output[i] = GeoJSON.getMultiGeomObject(geoJsonGeoms);
			}
			return output;
		}
		
		public static function test_getAllValues(column:IAttributeColumn, dataType:Class):Array
		{
			var t:int = getTimer();
			var keys:Array = column.keys;
			var values:Array = new Array(keys.length);
			for (var i:* in keys)
				values[i] = column.getValueFromKey(keys[i], dataType);
			weaveTrace(getTimer()-t);
			return values;
		}

		/**
		 * This function takes the common keys from a list of columns and generates a table of data values for each key from each specified column.
		 * @param columns A list of IAttributeColumns to compute a join table from.
		 * @param dataType The dataType parameter to pass to IAttributeColumn.getValueFromKey().
		 * @param allowMissingData If this is set to true, then all keys will be included in the join result.  Otherwise, only the keys that have associated values will be included.
		 * @param keyFilter Either an IKeyFilter or an Array of IQualifiedKey objects used to filter the results.
		 * @return An Array of Arrays, the first being IQualifiedKeys and the rest being Arrays data values from the given columns that correspond to the IQualifiedKeys. 
		 */
		public static function joinColumns(columns:Array, dataType:Object = null, allowMissingData:Boolean = false, keyFilter:Object = null):Array
		{
			var keys:Array;
			var key:IQualifiedKey;
			var column:IAttributeColumn;
			// if no keys are specified, get the keys from the columns
			if (keyFilter is Array)
			{
				keys = (keyFilter as Array).concat(); // make a copy so we don't modify the original
			}
			else if (keyFilter is IKeySet)
			{
				keys = (keyFilter as IKeySet).keys.concat(); // make a copy so we don't modify the original
			}
			else
			{
				// count the number of appearances of each key in each column
				var keyCounts:Dictionary = new Dictionary();
				for each (column in columns)
					for each (key in column ? column.keys : null)
						keyCounts[key] = int(keyCounts[key]) + 1;
				// get a list of keys
				keys = [];
				var filter:IKeyFilter = keyFilter as IKeyFilter;
				for (var qkey:* in keyCounts)
					if (allowMissingData || keyCounts[qkey] == columns.length)
						if (!filter || filter.containsKey(qkey))
							keys.push(qkey);
			}
			
			if (dataType is String)
				dataType = DataType.getClass(dataType as String);
			
			// put the keys in the result
			var result:Array = [keys];
			// get all the data values in the same order as the common keys
			for (var cIndex:int = 0; cIndex < columns.length; cIndex++)
			{
				column = columns[cIndex];
				
				var dt:Class = dataType as Class;
				if (!dt && column)
					dt = DataType.getClass(column.getMetadata(ColumnMetadata.DATA_TYPE));
				
				var values:Array = [];
				for (var kIndex:int = 0; kIndex < keys.length; kIndex++)
				{
					var value:* = column ? column.getValueFromKey(keys[kIndex] as IQualifiedKey, dt) : undefined;
					var isUndef:Boolean = StandardLib.isUndefined(value);
					if (!allowMissingData && isUndef)
					{
						// value is undefined, so remove this key and all associated data from the list
						for each (var array:Array in result)
							array.splice(kIndex, 1);
						kIndex--; // avoid skipping the next key
					}
					else if (isUndef)
						values.push(undefined);
					else
						values.push(value);
				}
				result.push(values);
			}
			return result;
		}
		/**
		 * @param attrCols An array of IAttributeColumns or ILinkableHashMaps containing IAttributeColumns.
		 * @return An Array of non-wrapper columns with duplicates removed.
		 */
		public static function getNonWrapperColumnsFromSelectableAttributes(attrCols:Array):Array
		{
			var columnLookup:Dictionary = new Dictionary(true);
			attrCols = attrCols.map(
				function(item:Object, i:int, a:Array):* {
					return item is ILinkableHashMap
					? (item as ILinkableHashMap).getObjects(IAttributeColumn)
					: item as IAttributeColumn;
				}
			);
			attrCols = VectorUtils.flatten(attrCols);
			attrCols = attrCols.map(
				function(column:IAttributeColumn, i:int, a:Array):IAttributeColumn {
					return hack_findNonWrapperColumn(column);
				}
			).filter(
				function(column:IAttributeColumn, i:int, a:Array):Boolean {
					if (!column || columnLookup[column])
						return false;
					columnLookup[column] = true;
					return true;
				}
			);
			return attrCols;
		}
		/**
		 * This function takes an array of attribute columns, a set of keys, and the type of the columns
		 * @param attrCols An array of IAttributeColumns or ILinkableHashMaps containing IAttributeColumns.
		 * @param subset An IKeyFilter or IKeySet specifying which keys to include in the CSV output, or null to indicate all keys available in the Attributes.
		 * @param dataType
		 * @return A string containing a CSV-formatted table containing the attributes of the requested keys.
		 */
		public static function generateTableCSV(attrCols:Array, subset:IKeyFilter = null, dataType:Class = null):String
		{
			SecondaryKeyNumColumn.allKeysHack = true; // dimension slider hack
			
			var records:Array = [];
			attrCols = getNonWrapperColumnsFromSelectableAttributes(attrCols);
			var columnTitles:Array = attrCols.map(
				function(column:IAttributeColumn, i:int, a:Array):String {
					return getTitle(column);
				}
			);
			var keys:Array;
			if (!subset)
				keys = getAllKeys(attrCols);
			else
				keys = getAllKeys(attrCols).filter(function(key:IQualifiedKey, idx:*, arr:Array):Boolean { return subset.containsKey(key);});
			
			var keyTypeMap:Object = {};				
			// create the data for each column in each selected row
			for each (var key:IQualifiedKey in keys)
			{
				var record:Object = {};
				// each record has a property named after the keyType equal to the key value				
				record[key.keyType] = key.localName;
				keyTypeMap[key.keyType] = true;
				
				for (var i:int = 0; i < attrCols.length; i++)
				{
					var col:IAttributeColumn = attrCols[i] as IAttributeColumn;
					var dt:Class = dataType || DataType.getClass(col.getMetadata(ColumnMetadata.DATA_TYPE));
					var value:Object = col.getValueFromKey(key, dt);
					if (StandardLib.isDefined(value))
						record[columnTitles[i]] = value;
				}
				records.push(record);
			}
			
			// update the list of headers before generating the table
			for (var keyType:String in keyTypeMap)
				columnTitles.unshift(keyType);
			
			SecondaryKeyNumColumn.allKeysHack = false; // dimension slider hack
			
			var rows:Array = WeaveAPI.CSVParser.convertRecordsToRows(records, columnTitles);
			return WeaveAPI.CSVParser.createCSV(rows);
		}

		/**
		 * This function will compute the union of a list of IKeySets.
		 * @param inputKeySets An Array of IKeySets (can be IAttributeColumns).
		 * @return The list of unique keys contained in all the inputKeySets.
		 */
		public static function getAllKeys(inputKeySets:Array):Array
		{
			var lookup:Dictionary = new Dictionary(true);
			var result:Array = [];
			for (var i:int = 0; i < inputKeySets.length; i++)
			{
				var keys:Array = (inputKeySets[i] as IKeySet).keys;
				for (var j:int = 0; j < keys.length; j++)
				{
					var key:IQualifiedKey = keys[j] as IQualifiedKey;
					if (lookup[key] === undefined)
					{
						lookup[key] = true;
						result.push(key);
					}
				}
			}
			return result;
		}
		
		/**
		 * This function will make sure the first IAttributeColumn in a linkable hash map is a DynamicColumn.
		 */		
		public static function forceFirstColumnDynamic(columnHashMap:ILinkableHashMap):void
		{
			var cols:Array = columnHashMap.getObjects(IAttributeColumn);
			if (cols.length == 0)
			{
				// just create a new dynamic column
				columnHashMap.requestObject(null, DynamicColumn, false);
			}
			else if (!(cols[0] is DynamicColumn))
			{
				// don't run callbacks while we edit session state
				getCallbackCollection(columnHashMap).delayCallbacks();
				// remember the name order
				var names:Array = columnHashMap.getNames();
				// remember the session state of the first column
				var state:Array = columnHashMap.getSessionState();
				state.length = 1; // only keep first column
				// overwrite existing column, reusing the same name
				var newCol:DynamicColumn = columnHashMap.requestObject(names[0], DynamicColumn, false);
				// copy the old col inside the new col
				newCol.setSessionState(state, true);
				// restore name order
				columnHashMap.setNameOrder(names);
				// done editing session state
				getCallbackCollection(columnHashMap).resumeCallbacks();
			}
		}
		
		/**
		 * Retrieves a metadata value from a list of columns if they all share the same value.
		 * @param columns The columns.
		 * @param propertyName The metadata property name.
		 * @return The metadata value if it is the same across all columns, or null if not. 
		 */		
		public static function getCommonMetadata(columns:Array, propertyName:String):String
		{
			var value:String;
			for (var i:int = 0; i < columns.length; i++)
			{
				var column:IAttributeColumn = columns[i] as IAttributeColumn;
				if (i == 0)
					value = column.getMetadata(propertyName);
				else if (value != column.getMetadata(propertyName))
					return null;
			}
			return value;
		}
		
		public static function getAllCommonMetadata(columns:Array):Object
		{
			var output:Object = {};
			if (!columns.length)
				return output;
			// We only need to get property names from the first column
			// because we only care about metadata common to all columns.
			for each (var key:String in columns[0].getMetadataPropertyNames())
			{
				var value:String = getCommonMetadata(columns, key);
				if (value)
					output[key] = value;
			}
			return output;
		}
		
		private static const _preferredMetadataPropertyOrder:Array = 'title,keyType,dataType,number,string,min,max,year'.split(',');
		public static function sortMetadataPropertyNames(names:Array):void
		{
			StandardLib.sortOn(names, [_preferredMetadataPropertyOrder.indexOf, names]);
		}
		
		/**
		 * This will initialize selectable attributes using a list of columns and/or column references.
		 * @param selectableAttributes An Array of IColumnWrapper and/or ILinkableHashMaps to initialize.
		 * @param input An Array of IAttributeColumn and/or IColumnReference objects. If not specified, getColumnsWithCommonKeyType() will be used.
		 * @see #getColumnsWithCommonKeyType()
		 */
		public static function initSelectableAttributes(selectableAttributes:Array, input:Array = null):void
		{
			if (!input)
				input = getColumnsWithCommonKeyType();
			
			for (var i:int = 0; i < selectableAttributes.length; i++)
				initSelectableAttribute(selectableAttributes[i], input[i % input.length]);
		}
		
		/**
		 * Gets a list of columns with a common keyType.
		 */
		public static function getColumnsWithCommonKeyType(keyType:String = null):Array
		{
			var columns:Array = getLinkableDescendants(WeaveAPI.globalHashMap, ReferencedColumn);
			
			// if keyType not specified, find the most common keyType
			if (!keyType)
			{
				var keyTypeCounts:Object = new Object();
				for each (var column:IAttributeColumn in columns)
				keyTypeCounts[ColumnUtils.getKeyType(column)] = int(keyTypeCounts[ColumnUtils.getKeyType(column)]) + 1;
				var count:int = 0;
				for (var kt:String in keyTypeCounts)
					if (keyTypeCounts[kt] > count)
						count = keyTypeCounts[keyType = kt];
			}
			
			// remove columns not of the selected key type
			var n:int = 0;
			for (var i:int = 0; i < columns.length; i++)
				if (ColumnUtils.getKeyType(columns[i]) == keyType)
					columns[n++] = columns[i];
			columns.length = n;
			
			return columns;
		}
		
		/**
		 * This will initialize one selectable attribute using a column or column reference. 
		 * @param selectableAttribute A selectable attribute (IColumnWrapper/ILinkableHashMap/ReferencedColumn)
		 * @param column_or_columnReference Either an IAttributeColumn or an ILinkableHashMap
		 * @param clearHashMap If the selectableAttribute is an ILinkableHashMap, all objects will be removed from it prior to adding a column.
		 */
		public static function initSelectableAttribute(selectableAttribute:Object, column_or_columnReference:Object, clearHashMap:Boolean = true):void
		{
			var inputCol:IAttributeColumn = column_or_columnReference as IAttributeColumn;
			var inputRef:IColumnReference = column_or_columnReference as IColumnReference;
			
			var outputRC:ReferencedColumn = selectableAttribute as ReferencedColumn;
			if (outputRC)
			{
				var inputRC:ReferencedColumn;
				if (inputCol)
					inputRC = inputCol as ReferencedColumn
						|| getLinkableDescendants(inputCol, ReferencedColumn)[0] as ReferencedColumn;
				
				if (inputRC)
					copySessionState(inputRC, outputRC);
				else if (inputRef)
					outputRC.setColumnReference(inputRef.getDataSource(), inputRef.getColumnMetadata());
				else
					outputRC.setColumnReference(null, null);
			}
			
			var foundGlobalColumn:Boolean = false;
			if (selectableAttribute is DynamicColumn)
				foundGlobalColumn = (selectableAttribute as DynamicColumn).targetPath != null;
			if (selectableAttribute is ExtendedDynamicColumn)
				foundGlobalColumn = (selectableAttribute as ExtendedDynamicColumn).internalDynamicColumn.targetPath != null;
			var outputDC:DynamicColumn = ColumnUtils.hack_findInternalDynamicColumn(selectableAttribute as IColumnWrapper);
			if (outputDC && (outputDC.getInternalColumn() == null || !foundGlobalColumn))
			{
				if (inputCol)
				{
					if (inputCol is DynamicColumn)
						copySessionState(inputCol, outputDC);
					else
						outputDC.requestLocalObjectCopy(inputCol);
				}
				else if (inputRef)
					ReferencedColumn(
						outputDC.requestLocalObject(ReferencedColumn, false)
					).setColumnReference(
						inputRef.getDataSource(),
						inputRef.getColumnMetadata()
					);
				else
					outputDC.removeObject();
			}
			
			var outputHash:ILinkableHashMap = selectableAttribute as ILinkableHashMap;
			if (outputHash)
			{
				if (clearHashMap)
					outputHash.removeAllObjects()
				if (inputCol)
					outputHash.requestObjectCopy(null, inputCol);
				else if (inputRef)
					ReferencedColumn(
						outputHash.requestObject(null, ReferencedColumn, false)
					).setColumnReference(
						inputRef.getDataSource(),
						inputRef.getColumnMetadata()
					);
			}
		}
		
		//todo: (cached) get sorted index from a key and a column
		
		//todo: (cached) get bins from a column with a filter applied
		
		public static function unlinkNestedColumns(columnWrapper:IColumnWrapper):void
		{
			var col:IColumnWrapper = columnWrapper;
			while (col)
			{
				var dc:DynamicColumn = col as DynamicColumn;
				var edc:ExtendedDynamicColumn = col as ExtendedDynamicColumn;
				if (dc && dc.globalName) // if linked
				{
					// unlink
					dc.globalName = null;
					// prevent infinite loop
					if (dc.globalName)
						break;
					// restart from selected
					col = columnWrapper;
				}
				else if (edc && edc.internalDynamicColumn.globalName) // if linked
				{
					// unlink
					edc.internalDynamicColumn.globalName = null;
					// prevent infinite loop
					if (edc.internalDynamicColumn.globalName)
						break;
					// restart from selected
					col = columnWrapper;
				}
				else
				{
					// get nested column
					col = col.getInternalColumn() as IColumnWrapper;
				}
			}
		}
	}
}
