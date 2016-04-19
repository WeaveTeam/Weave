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
	import weavejs.api.core.DynamicState;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnReference;
	import weavejs.api.data.IColumnWrapper;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IKeyFilter;
	import weavejs.api.data.IKeySet;
	import weavejs.api.data.IPrimitiveColumn;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.data.column.DynamicColumn;
	import weavejs.data.column.ExtendedDynamicColumn;
	import weavejs.data.column.ReferencedColumn;
	import weavejs.data.column.SecondaryKeyNumColumn;
	import weavejs.data.hierarchy.HierarchyUtils;
	import weavejs.geom.BLGNode;
	import weavejs.geom.Bounds2D;
	import weavejs.geom.GeneralizedGeometry;
	import weavejs.geom.GeoJSON;
	import weavejs.geom.Point;
	import weavejs.util.ArrayUtils;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
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
			var title:String = column.getMetadata(ColumnMetadata.TITLE) || Weave.lang("(Data unavailable)");
			
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
				cols = Weave.getDescendants(column, ReferencedColumn);
			for (var i:int = 0; i < cols.length; i++)
				sources.push((cols[i] as ReferencedColumn).getDataSource());
			return ArrayUtils.union(sources);
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
			columnWrapper = columnWrapper as IColumnWrapper;
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
		
		public static function hack_findHierarchyNode(columnWrapper:IColumnWrapper):/*/IWeaveTreeNode & IColumnReference/*/IWeaveTreeNode
		{
			var dc:DynamicColumn = hack_findInternalDynamicColumn(columnWrapper);
			if (!dc)
				return null;
			var rc:ReferencedColumn = dc.target as ReferencedColumn;
			return rc ? rc.getHierarchyNode() : null;
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
				var simplifiedGeom:Array/*Vector.<Vector.<BLGNode>>*/ = genGeom.getSimplifiedGeometry();
				var newSimplifiedGeom:Array = [];			
				for (var iSimplifiedGeom:int; iSimplifiedGeom < simplifiedGeom.length; ++iSimplifiedGeom)
				{
					var nodeVector:Array/*Vector.<BLGNode>*/ = simplifiedGeom[iSimplifiedGeom];
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
		 * @return An Array of GeoJson Geometry objects corresponding to the keys.  The Array may be sparse if there are no coordinates for some of the keys.
		 */
		public static function getGeoJsonGeometries(geometryColumn:IAttributeColumn, keys:Array, minImportance:Number = 0, visibleBounds:Bounds2D = null):Array
		{
			var map_inputGeomArray_outputMultiGeom:Object = new JS.WeakMap();
			var output:Array = new Array(keys.length);
			var multiGeom:Object;
			for (var i:int = 0; i < keys.length; i++)
			{
				var key:IQualifiedKey = keys[i];
				var inputGeomArray:Array = geometryColumn.getValueFromKey(key, Array) as Array;
				if (inputGeomArray)
				{
					if (map_inputGeomArray_outputMultiGeom.has(inputGeomArray))
					{
						multiGeom = map_inputGeomArray_outputMultiGeom.get(inputGeomArray);
					}
					else
					{
						var outputGeomArray:Array = [];
						for each (var inputGeom:GeneralizedGeometry in inputGeomArray)
						{
							var outputGeom:Object = inputGeom.toGeoJson(minImportance, visibleBounds);
							if (outputGeom)
								outputGeomArray.push(outputGeom);
						}
						multiGeom = outputGeomArray.length ? GeoJSON.getMultiGeomObject(outputGeomArray) : null;
						map_inputGeomArray_outputMultiGeom.set(inputGeomArray, multiGeom);
					}
					if (multiGeom)
						output[i] = multiGeom;
				}
			}
			return output;
		}
		
		public static function test_getAllValues(column:IAttributeColumn, dataType:Class):Array
		{
			var t:int = JS.now();
			var keys:Array = column.keys;
			var values:Array = new Array(keys.length);
			for (var i:* in keys)
				values[i] = column.getValueFromKey(keys[i], dataType);
			JS.log(JS.now()-t);
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
				var map_key_count:Object = new JS.Map();
				for each (column in columns)
				{
					var columnKeys:Array = column ? column.keys : null;
					for each (key in columnKeys)
						map_key_count.set(key, (map_key_count.get(key)|0) + 1);
				}
				// get a list of keys
				keys = [];
				var filter:IKeyFilter = keyFilter as IKeyFilter;
				var mapKeys:Array = JS.mapKeys(map_key_count);
				for each (var qkey:* in mapKeys)
					if (allowMissingData || map_key_count.get(qkey) == columns.length)
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
				
				var dt:Class = JS.asClass(dataType);
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
		 * Generates records using a custom format.
		 * @param format An object mapping names to IAttributeColumn objects or constant values to be included in every record.
		 *               You can nest Objects or Arrays.
		 *               If you want each record to include its corresponding key, include a property with a value equal to weavejs.api.data.IQualifiedKey.
		 * @param keys An Array of IQualifiedKeys
		 * @param dataType A Class specifying the dataType to retrieve from columns: String/Number/Date/Array (default is Array)
		 *                 You can also specify different data types in a structure matching that of the format object.
		 * @param keyProperty The property name which should be used to store the IQualifiedKey for a record.
		 * @return An array of record objects matching the structure of the format object.
		 */
		public static function getRecords(format:Object, keys:Array = null, dataType:Object = null):Array
		{
			if (!keys)
				keys = getAllKeys(getColumnsFromFormat(format, []));
			var records:Array = new Array(keys.length);
			for (var i:String in keys)
				records[i] = getRecord(format, keys[i], dataType);
			return records;
		}
		
		private static function getColumnsFromFormat(format:Object, output:Array):Array
		{
			if (format is IAttributeColumn)
				output.push(format);
			else if (!JS.isPrimitive(format))
				for each (var item:Object in format)
					getColumnsFromFormat(item, output);
			return output;
		}
		
		/**
		 * Generates a record using a custom format.
		 * @param format An object mapping names to IAttributeColumn objects or constant values to be included in every record.
		 *               You can nest Objects or Arrays.
		 *               If you want the record to include its corresponding key, include include a property with a value equal to weavejs.api.data.IQualifiedKey.
		 * @param key An IQualifiedKey
		 * @param dataType A Class specifying the dataType to retrieve from columns: String/Number/Date/Array (default is Array)
		 *                 You can also specify different data types in a structure matching that of the format object.
		 * @return A record object matching the structure of the format object.
		 */
		public static function getRecord(format:Object, key:IQualifiedKey, dataType:Object):Object
		{
			if (format === IQualifiedKey)
				return key;
			
			// check for primitive values
			if (format === null || typeof format !== 'object')
				return format;
			
			var dataTypeClass:Class = JS.asClass(dataType || Array);
			var column:IAttributeColumn = format as IAttributeColumn;
			if (column)
			{
				var value:* = column.getValueFromKey(key, dataTypeClass);
				if (value === undefined)
					value = null;
				return value;
			}
			
			var record:Object = format is Array ? [] : {};
			for (var prop:String in format)
				record[prop] = getRecord(format[prop], key, dataTypeClass || dataType[prop]);
			return record;
		}
		
		/**
		 * @param attrCols An array of IAttributeColumns or ILinkableHashMaps containing IAttributeColumns.
		 * @return An Array of non-wrapper columns with duplicates removed.
		 */
		public static function getNonWrapperColumnsFromSelectableAttributes(attrCols:Array):Array
		{
			var map_column:Object = new JS.WeakMap();
			attrCols = attrCols.map(
				function(item:Object, i:int, a:Array):* {
					return item is ILinkableHashMap
					? (item as ILinkableHashMap).getObjects(IAttributeColumn)
					: item as IAttributeColumn;
				}
			);
			attrCols = ArrayUtils.flatten(attrCols);
			attrCols = attrCols.map(
				function(column:IAttributeColumn, i:int, a:Array):IAttributeColumn {
					return hack_findNonWrapperColumn(column);
				}
			).filter(
				function(column:IAttributeColumn, i:int, a:Array):Boolean {
					if (!column || map_column.get(column))
						return false;
					map_column.set(column, true);
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
			var map_key:Object = new JS.WeakMap();
			var result:Array = [];
			for (var i:int = 0; i < inputKeySets.length; i++)
			{
				var keys:Array = (inputKeySets[i] as IKeySet).keys;
				for (var j:int = 0; j < keys.length; j++)
				{
					var key:IQualifiedKey = keys[j] as IQualifiedKey;
					if (!map_key.has(key))
					{
						map_key.set(key, true);
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
				Weave.getCallbacks(columnHashMap).delayCallbacks();
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
				Weave.getCallbacks(columnHashMap).resumeCallbacks();
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
		
		public static var firstDataSet:Array/*/<IColumnReference>/*/;
		
		/**
		 * Finds a set of columns from available data sources, preferring ones that are already in use. 
		 */
		public static function findFirstDataSet(root:ILinkableHashMap):Array/*/<IColumnReference>/*/
		{
			if (firstDataSet && firstDataSet.length)
				return firstDataSet;
			
			var ref:IColumnReference;
			for each (var column:ReferencedColumn in Weave.getDescendants(root, ReferencedColumn))
			{
				ref = column.getHierarchyNode() as IColumnReference;
				if (ref)
					break;
			}
			if (!ref)
			{
				for each (var source:IDataSource in Weave.getDescendants(root, IDataSource))
				{
					ref = findFirstColumnReference(source.getHierarchyRoot());
					if (ref)
						break;
				}
			}
			
			return ref ? HierarchyUtils.findSiblingNodes(ref.getDataSource(), ref.getColumnMetadata()) : [];
		}
		
		private static function findFirstColumnReference(node:IWeaveTreeNode):IColumnReference
		{
			var ref:IColumnReference = node as IColumnReference;
			if (ref && ref.getColumnMetadata())
				return ref;
			
			if (!node.isBranch())
				return null;
			
			for each (var child:IWeaveTreeNode in node.getChildren())
			{
				ref = findFirstColumnReference(child);
				if (ref)
					return ref;
			}
			return null;
		}
		
		/**
		 * This will initialize selectable attributes using a list of columns and/or column references.
		 * @param selectableAttributes An Array of IColumnWrapper and/or ILinkableHashMaps to initialize.
		 * @param input An Array of IAttributeColumn and/or IColumnReference objects. If not specified, getColumnsWithCommonKeyType() will be used.
		 * @see #getColumnsWithCommonKeyType()
		 */
		public static function initSelectableAttributes(selectableAttributes:Array/*/<IColumnWrapper | ILinkableHashMap>/*/, input:Array/*/<IAttributeColumn | IColumnReference>/*/ = null):void
		{
			if (!input)
				input = getColumnsWithCommonKeyType(Weave.getRoot(selectableAttributes[0]));
			
			for (var i:int = 0; i < selectableAttributes.length; i++)
				initSelectableAttribute(selectableAttributes[i], input[i % input.length]);
		}
		
		/**
		 * Gets a list of columns with a common keyType.
		 */
		public static function getColumnsWithCommonKeyType(root:ILinkableHashMap, keyType:String = null):Array
		{
			var columns:Array = Weave.getDescendants(root, ReferencedColumn);
			
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
		
		public static function replaceColumnsInHashMap(destination:ILinkableHashMap, columnReferences:Array/*/<IColumnReference>/*/):void
		{
			var className:String = WeaveAPI.ClassRegistry.getClassName(ReferencedColumn);
			var baseName:String = className.split('.').pop();
			var names:Array = destination.getNames();
			var newState:Array = [];
			for (var iRef:int = 0; iRef < columnReferences.length; iRef++)
			{
				var ref:IColumnReference = columnReferences[iRef] as IColumnReference;
				var objectName:String = names[newState.length] || destination.generateUniqueName(baseName);
				var sessionState:Object = ReferencedColumn.generateReferencedColumnStateFromColumnReference(ref);
				newState.push(DynamicState.create(objectName, className, sessionState));
			}
			destination.setSessionState(newState, true);
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
						|| Weave.getDescendants(inputCol, ReferencedColumn)[0] as ReferencedColumn;
				
				if (inputRC)
					Weave.copyState(inputRC, outputRC);
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
						Weave.copyState(inputCol, outputDC);
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
