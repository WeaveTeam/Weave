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

package weave.utils
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IDataSource;
	import weave.api.data.IKeySet;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.getLinkableOwner;
	import weave.compiler.StandardLib;
	import weave.core.LinkableHashMap;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.SecondaryKeyNumColumn;
	import weave.data.QKeyManager;
	import weave.primitives.BLGNode;
	import weave.primitives.GeneralizedGeometry;
	
	/**
	 * This class contains static functions that access values from IAttributeColumn objects.
	 * 
	 * @author adufilie
	 */
	public class ColumnUtils
	{
		/**
		 * This is a shortcut for column.getMetadata(AttributeColumnMetadata.TITLE).
		 * @param column A column to get the title of.
		 * @return The title of the column.
		 */		
		public static function getTitle(column:IAttributeColumn):String
		{
			var title:String = column.getMetadata(AttributeColumnMetadata.TITLE) || 'Undefined';
			
			// debug code
			if (false)
			{
				var keyType:String = column.getMetadata(AttributeColumnMetadata.KEY_TYPE);
				if (keyType)
					title += " (Key type: " + keyType + ")";
				else
					title += " (No key type)";
			}

			return title;
		}
		
		/**
		 * Temporary solution
		 * @param column
		 * @return 
		 */		
		public static function getDataSource(column:IAttributeColumn):String
		{
			var name:String;
			var nameMap:Object = {};
			var refs:Array = getLinkableDescendants(column, IColumnReference);
			for (var i:int = 0; i < refs.length; i++)
			{
				var ref:IColumnReference = refs[i];
				var source:IDataSource = ref.getDataSource();
				var sourceOwner:ILinkableHashMap = getLinkableOwner(source) as ILinkableHashMap;
				if (!sourceOwner)
					continue;
				name = sourceOwner.getName(source);
				nameMap[name] = true;
			}
			var names:Array = [];
			for (name in nameMap)
				names.push(name);
			return names.join(', ');
		}

		/**
		 * This function gets the keyType of a column, either from the metadata or from the actual keys.
		 * @param column A column to get the keyType of.
		 * @return The keyType of the column.
		 */
		public static function getKeyType(column:IAttributeColumn):String
		{
			// first try getting the keyType from the metadata.
			var keyType:String = column.getMetadata(AttributeColumnMetadata.KEY_TYPE);
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
			return column.getMetadata(AttributeColumnMetadata.DATA_TYPE);
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
		
		/**
		 * This is mostly a convenience function to call through Javascript. For example,
		 * a user could invoke 'KeySet.replaceKeys( getQKeys(keyObjects) )' where keyObjects
		 * is an array of generic objects in Javascript.  
		 * @param genericObjects An array of generic objects with <code>keyType</code>
		 * and <code>localName</code> properties.
		 * @return An array of IQualifiedKey objects.
		 * 
		 */		
		public static function getQKeys(genericObjects:Array):Array
		{
			var result:Array = [];
			
			for each (var key:Object in genericObjects)
			{
				var qkey:IQualifiedKey = getQKey(key);
				result.push(qkey);
			}

			return result;
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
				return StandardLib.asBoolean( column.getValueFromKey(qkey) );
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
			var genGeoms:Array = geometryColumn.getValueFromKey(qkey) as Array;
			
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
		 * This function takes the common keys from a list of columns and generates a table of data values for each key from each specified column.
		 * @param columns A list of IAttributeColumns to compute a join table from.
		 * @param dataType The dataType parameter to pass to IAttributeColumn.getValueFromKey().
		 * @param allowMissingData If this is set to true, then all keys will be included in the join result.  Otherwise, only the keys that have associated values will be included.
		 * @param keys A list of IQualifiedKey objects to use to filter the results.
		 * @return An Array of Arrays, the first being IQualifiedKeys and the rest being Arrays data values from the given columns that correspond to the IQualifiedKeys. 
		 */
		public static function joinColumns(columns:Array, dataType:Class = null, allowMissingData:Boolean = false, keys:Array = null):Array
		{
			var key:IQualifiedKey;
			var column:IAttributeColumn;
			// if no keys are specified, get the keys from the columns
			if (keys == null)
			{
				// count the number of appearances of each key in each column
				var keyCounts:Dictionary = new Dictionary();
				for each (column in columns)
					for each (key in column.keys)
						keyCounts[key] = int(keyCounts[key]) + 1;
				// get a list of keys that appeared in every column
				keys = [];
				for (var qkey:* in keyCounts)
					if (allowMissingData || keyCounts[qkey] == columns.length)
						keys.push(qkey);
			}
			else
			{
				keys = keys.concat(); // make a copy so we don't modify the original
			}
			// put the keys in the result
			var result:Array = [keys];
			// get all the data values in the same order as the common keys
			for (var cIndex:int = 0; cIndex < columns.length; cIndex++)
			{
				column = columns[cIndex];
				var values:Array = [];
				for (var kIndex:int = 0; kIndex < keys.length; kIndex++)
				{
					var value:* = column.getValueFromKey(keys[kIndex] as IQualifiedKey, dataType);
					if (!allowMissingData && StandardLib.isUndefined(value))
					{
						// value is undefined, so remove this key and all associated data from the list
						for each (var array:Array in result)
							array.splice(kIndex, 1);
						kIndex--; // avoid skipping the next key
					}
					else
					{
						values.push(value);
					}
				}
				result.push(values);
			}
			return result;
		}
		
		public static function generateTableCSV(attrCols:Array,keys:* = null,dataType:Class = null):String{
			
			
			SecondaryKeyNumColumn.allKeysHack = true; // dimension slider hack
			
			var records:Array = [];				
			// get the list of column titles
			//var attrCols:Array = getSelectableAttributes();
			var definedAttrCols:Array = [];				
			var columnTitles:Array = [];
			var i:int;
			for ( i = 0; i < attrCols.length; i++){
				// to make sure only available attributes are added for export
				if ((attrCols[i] is  IColumnWrapper) && (attrCols[i] as  IColumnWrapper).getInternalColumn()){
					columnTitles.push(ColumnUtils.getTitle(attrCols[i]));
					definedAttrCols.push(attrCols[i]);
				}					
				if (attrCols[i] is  LinkableHashMap)  {
					var hashMapColumns:Array = (attrCols[i] as  LinkableHashMap).getObjects();
					for (var j:int = 0; j < hashMapColumns.length; j++){
						if ((hashMapColumns[j] as  IColumnWrapper).getInternalColumn()){
							columnTitles.push(ColumnUtils.getTitle(hashMapColumns[j]));
							definedAttrCols.push(hashMapColumns[j]);
						}								
					}
				}
			}
			if(!keys){
				keys = getAllKeys(definedAttrCols);
			}
			
			var keyTypeMap:Object = {};				
			// create the data for each column in each selected row
			//	var keys:* = _plotter.keySet.keys;
			for each (var item:Object in keys)
			{
				var key:IQualifiedKey = item as IQualifiedKey;
				var record:Object = {};
				// each record has a property named after the keyType equal to the key value				
				record[key.keyType] = key.localName;
				keyTypeMap[key.keyType] = true;
				
				for (i = 0; i < definedAttrCols.length; i++)
				{
					var value:Object = (definedAttrCols[i] as IAttributeColumn).getValueFromKey(key, dataType);
					if (!isNaN(value as Number))
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
				// remember the order
				var names:Array = columnHashMap.getNames();
				
				// create a new wrapper column
				var newCol:DynamicColumn = columnHashMap.requestObject(null, DynamicColumn, false);
				// copy the old col inside the new col
				newCol.requestLocalObjectCopy(cols[0]);
				// remove old col
				columnHashMap.removeObject(columnHashMap.getName(cols[0]));
				
				// restore name order
				columnHashMap.setNameOrder(names);
				// done editing session state
				getCallbackCollection(columnHashMap).resumeCallbacks();
			}
		}
		
		//todo: (cached) get sorted index from a key and a column
		
		//todo: (cached) get bins from a column with a filter applied
	}
}
