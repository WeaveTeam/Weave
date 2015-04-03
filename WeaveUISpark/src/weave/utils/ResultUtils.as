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
	
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	
	import weave.Weave;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IQualifiedKey;
	import weave.data.AttributeColumns.CSVColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.KeySets.KeySet;
	
	public class ResultUtils
	{
		public function ResultUtils()
		{
		}
		
		public static function getAllObjectProperties(obj:Object):Array{
			var objPropertyArray:Array = new Array();
			for( var prop : * in obj){				
				objPropertyArray.push(prop);
			}
			return objPropertyArray;
		}
		
		public static function resultAsColorCol(colName:String,keys:Array,column:Object):void{
			var table:Array = [];
			for (var k:int = 0; k < keys.length; k++)
				table.push([(keys[k] as IQualifiedKey).localName, column[k]]);
			var testColumn:CSVColumn = WeaveAPI.globalHashMap.requestObject(colName, CSVColumn, false);
			testColumn.keyType.value = keys.length > 0 ? (keys[0] as IQualifiedKey).keyType : null;
			testColumn.numericMode.value = true;
			testColumn.data.setSessionState(table);
			testColumn.title.value =colName;
			Weave.defaultColorDataColumn.internalDynamicColumn.globalName = WeaveAPI.globalHashMap.getName(testColumn);
			
		}
		
		public static function resultAsSelection(keyType:String,columnObject:Object):void{
			var qkey:IQualifiedKey;
			var result:Dictionary = new Dictionary();
			var resultKeys:Array = [];							
			for (var key:String in columnObject)		{
				qkey = WeaveAPI.QKeyManager.getQKey(keyType, key);
				result[qkey] = columnObject[key];
				resultKeys.push(qkey);
			}			
			Weave.defaultSelectionKeySet.replaceKeys(resultKeys);			
		}
		
		public static function resultAsArrayCollection(objOfArrays:Object,displayAsSquareMatrix:Boolean = false):ArrayCollection{
			var arrayColl:ArrayCollection = new ArrayCollection();
			var objProps:Array = getAllObjectProperties(objOfArrays);
			var innerObj:Object = objOfArrays[objProps[0]];
			if(innerObj is Array){
				var innerArrayLen:int = (innerObj as Array).length;
				if(innerArrayLen == objProps.length){
					displayAsSquareMatrix = true;
				}
				for(var row:int =0 ; row < innerArrayLen;row++){
					var rowObject:Object = new Object();
					if(displayAsSquareMatrix){
						rowObject["key"] = objProps[row];
					}
					
					for(var col:int = 0 ; col < objProps.length ;col++){
						var property:String = objProps[col];
						rowObject[property] = objOfArrays[property][row];											
					}
					arrayColl.addItem(rowObject);
				}
			}
			return arrayColl;			
		}
		
		public static function resultAsNumberColumn( keys:Object , column:Object,columName:String = ""):NumberColumn{
			var numColumn:NumberColumn = new NumberColumn(<attribute title="{columnName}"/>);
			var keyVec:Vector.<IQualifiedKey> = Vector.<IQualifiedKey>(keys);
			if (column is Number)
				column = [column];
			var dataVec:Vector.<Number> = Vector.<Number>(column);
			numColumn.setRecords(keyVec, dataVec);
			return numColumn;
		}
		
		/**
		 * @return A multi-dimensional Array like [keys, [data1, data2, ...]] where keys implement IQualifiedKey
		 */
		public static function joinColumns(columns:Array):Array
		{
		var keys:Array = selection.keys.length > 0 ? selection.keys : null;
		//make dataype Null, so that columns will be sent as exact dataype to R
		//if mentioned as String or NUmber ,will convert all columns to String or Number .
		var result:Array = ColumnUtils.joinColumns(columns,null, true, keys);
		return [result.shift(),result];
		}
		
		public static function get selection():KeySet
		{
			return Weave.defaultSelectionKeySet;
		}
		
		public static function rResultToColumn(keys:Array, RresultArray:Array,Robj:Array):void
		{
			if (!keys)
				return;
			//Objects "(object{name: , value:}" are mapped whose value length that equals Keys length
			for (var p:int = 0; p < RresultArray.length; p++)
			{
				var data:Array = RresultArray[p].value as Array;
				if (!data || data.length != keys.length)
					continue;
				var title:String = RresultArray[p].name;
				if (data[0] is String)
				{
					var testStringColumn:StringColumn = WeaveAPI.globalHashMap.requestObject(title, StringColumn, false);
					var keyVec:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
					var dataVec:Vector.<String> = new Vector.<String>();
					VectorUtils.copy(keys, keyVec);
					VectorUtils.copy(Robj[p].value, dataVec);
					testStringColumn.setRecords(keyVec, dataVec);
					var meta:Object = {};
					meta[ColumnMetadata.TITLE] = title;
					if (keys.length > 0)
						meta[ColumnMetadata.KEY_TYPE] = (keys[0] as IQualifiedKey).keyType;
					testStringColumn.setMetadata(meta);
				}
				else
				{
					var table:Array = [];
					for (var k:int = 0; k < keys.length; k++)
						table.push([ (keys[k] as IQualifiedKey).localName, Robj[p].value[k] ]);
					
					//testColumn are named after respective Objects Name (i.e) object{name: , value:}
					var testColumn:CSVColumn = WeaveAPI.globalHashMap.requestObject(title, CSVColumn, false);
					testColumn.keyType.value = keys.length > 0 ? (keys[0] as IQualifiedKey).keyType : null;
					testColumn.numericMode.value = true;
					testColumn.data.setSessionState(table);
					testColumn.title.value = title;
				}
			}
	   }
	}
}
