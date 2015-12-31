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

package weavejs.data.column
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IKeySet;
	import weavejs.api.data.IPrimitiveColumn;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableBoolean;
	import weavejs.core.LinkableHashMap;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableVariable;
	import weavejs.data.EquationColumnLib;
	import weavejs.util.ArrayUtils;
	import weavejs.util.Dictionary2D;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	/**
	 * This is a column of data derived from an equation with variables.
	 * 
	 * @author adufilie
	 */
	public class EquationColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public static var debug:Boolean = false;
		
		public function EquationColumn()
		{
			super();
			setMetadataProperty(ColumnMetadata.TITLE, "Untitled Equation");
			//setMetadataProperty(AttributeColumnMetadata.DATA_TYPE, DataType.NUMBER);
			
			variables.childListCallbacks.addImmediateCallback(this, handleVariableListChange);
		}
		
		private function handleVariableListChange():void
		{
			// make callbacks trigger when statistics change for listed variables
			var newColumn:IAttributeColumn = variables.childListCallbacks.lastObjectAdded as IAttributeColumn;
			if (newColumn)
				Weave.getCallbacks(WeaveAPI.StatisticsCache.getColumnStatistics(newColumn)).addImmediateCallback(this, triggerCallbacks);
		}
		
		/**
		 * This is all the keys in all the variables columns
		 */
		private var _allKeys:Array = null;
		private var map_allKeys:Object;
		private var _allKeysTriggerCount:uint = 0;
		/**
		 * This is a cache of metadata values derived from the metadata session state.
		 */		
		private var _cachedMetadata:Object = {};
		private var _cachedMetadataTriggerCount:uint = 0;
		/**
		 * This is the Class corresponding to dataType.value.
		 */		
		private var _defaultDataType:Class = null;
		/**
		 * This is the function compiled from the equation.
		 */
		private var compiledEquation:Function = null;
		/**
		 * This is the last error thrown from the compiledEquation.
		 */		
		private var _lastError:String;
		/**
		 * This is a mapping from keys to cached data values.
		 */
		private var d2d_key_dataType_value:Dictionary2D = new Dictionary2D();
		/**
		 * This is used to determine when to clear the cache.
		 */		
		private var _cacheTriggerCount:uint = 0;
		/**
		 * This is used as a placeholder in d2d_key_dataType_value.
		 */		
		private static const UNDEFINED:Object = {};
		
		
		/**
		 * This is the equation that will be used in getValueFromKey().
		 */
		public const equation:LinkableString = Weave.linkableChild(this, LinkableString);
		/**
		 * This is a list of named variables made available to the compiled equation.
		 */
		public const variables:LinkableHashMap = Weave.linkableChild(this, LinkableHashMap);
		
		/**
		 * This holds the metadata for the column.
		 */
		public const metadata:LinkableVariable = Weave.linkableChild(this, new LinkableVariable(null, verifyMetadata));
		
		private function verifyMetadata(value:Object):Boolean
		{
			return typeof value == 'object';
		}

		/**
		 * Specify whether or not we should filter the keys by the column's keyType.
		 */
		public const filterByKeyType:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(false));
		
		/**
		 * This function intercepts requests for dataType and title metadata and uses the corresponding linkable variables.
		 * @param propertyName A metadata property name.
		 * @return The requested metadata value.
		 */
		override public function getMetadata(propertyName:String):String
		{
			if (_cachedMetadataTriggerCount != triggerCounter)
			{
				_cachedMetadata = {};
				_cachedMetadataTriggerCount = triggerCounter;
			}
			
			if (_cachedMetadata.hasOwnProperty(propertyName))
				return _cachedMetadata[propertyName] as String;
			
			_cachedMetadata[propertyName] = undefined; // prevent infinite recursion
			
			var value:String = metadata.state ? metadata.state[propertyName] as String : null;
			if (value != null)
			{
				if (value.charAt(0) == '{' && value.charAt(value.length - 1) == '}')
				{
					try
					{
						var func:Function = JS.compile(value);
						value = func.apply(this, arguments);
					}
					catch (e:*)
					{
						errorHandler(e);
					}
				}
			}
			else if (propertyName == ColumnMetadata.KEY_TYPE)
			{
				var cols:Array = variables.getObjects(IAttributeColumn);
				if (cols.length)
					value = (cols[0] as IAttributeColumn).getMetadata(propertyName);
			}
			
			_cachedMetadata[propertyName] = value;
			return value;
		}
		
		private function errorHandler(e:*):void
		{
			var str:String = e is Error ? e.message : String(e);
			if (_lastError != str)
			{
				_lastError = str;
				JS.error(e);
			}
		}
		
		override public function setMetadata(value:Object):void
		{
			metadata.setSessionState(value);
		}
		
		override public function getMetadataPropertyNames():Array
		{
			return JS.objectKeys(metadata.getSessionState());
		}

		/**
		 * This function will store an individual metadata value in the metadata linkable variable.
		 * @param propertyName
		 * @param value
		 */
		public function setMetadataProperty(propertyName:String, value:String):void
		{
			value = StandardLib.trim(value);
			var _metadata:Object = metadata.state || {};
			_metadata[propertyName] = value;
			metadata.state = _metadata; // this triggers callbacks
		}
		
		/**
		 * This function creates an object in the variables LinkableHashMap if it doesn't already exist.
		 * If there is an existing object associated with the specified name, it will be kept if it
		 * is the specified type, or replaced with a new instance of the specified type if it is not.
		 * @param name The identifying name of a new or existing object.
		 * @param classDef The Class of the desired object type.
		 * @return The object associated with the requested name of the requested type, or null if an error occurred.
		 */
		public function requestVariable(name:String, classDef:Class, lockObject:Boolean = false):*
		{
			return variables.requestObject(name, classDef, lockObject);
		}

		/**
		 * @return The keys associated with this EquationColumn.
		 */
		override public function get keys():Array
		{
			// return all the keys of all columns in the variables list
			if (_allKeysTriggerCount != variables.triggerCounter)
			{
				_allKeys = null;
				map_allKeys = new JS.WeakMap();
				_allKeysTriggerCount = variables.triggerCounter; // prevent infinite recursion

				var variableColumns:Array = variables.getObjects(IKeySet);

				_allKeys = ArrayUtils.union.apply(ArrayUtils, ArrayUtils.pluck(variableColumns, 'keys'));

				if (filterByKeyType.value && (_allKeys.length > 0))
				{
					var keyType:String = this.getMetadata(ColumnMetadata.KEY_TYPE);
					_allKeys = _allKeys.filter(function filter(key:IQualifiedKey, i:int, a:Array):Boolean {
						return key.keyType == keyType;
					});
				}
				for each (var key:IQualifiedKey in _allKeys)
					map_allKeys.set(key, true);
			}
			return _allKeys || [];
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return keys && map_allKeys.has(key);
		}
		
		/**
		 * Compiles the equation if it has changed, and returns any compile error message that was thrown.
		 */
		public function validateEquation():String
		{
			if (_cacheTriggerCount == triggerCounter)
				return _compileError;
			
			_cacheTriggerCount = triggerCounter;
			_compileError = null;
			
			try
			{
				compiledEquation = JS.compile(equation.value, ['key', 'dataType'].concat(variables.getNames()));
				d2d_key_dataType_value = new Dictionary2D(); // create a new cache
			}
			catch (e:Error)
			{
				// if compiling fails
				compiledEquation = function(..._):* { return undefined; };
				_compileError = e.message;
			}
			
			return _compileError;
		}
		
		private var _compileError:String;
		
		/**
		 * @return The result of the compiled equation evaluated at the given record key.
		 * @see weave.api.data.IAttributeColumn
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			// reset cached values if necessary
			if (_cacheTriggerCount != triggerCounter)
				validateEquation();
			
			// if dataType not specified, use default type specified in metadata
			if (dataType == null)
				dataType = Array;
			
			// check the cache
			var value:* = d2d_key_dataType_value.get(key, dataType);
			// define cached value if missing
			if (value === undefined)
			{
				// prevent recursion caused by compiledEquation
				d2d_key_dataType_value.set(key, dataType, UNDEFINED);
				
				// prepare EquationColumnLib static parameter before calling the compiled equation
				var prevKey:IQualifiedKey = EquationColumnLib.currentRecordKey;
				EquationColumnLib.currentRecordKey = key;
				try
				{
					var args:Array = variables.getObjects();
					args.unshift(key, dataType);
					value = compiledEquation.apply(this, args);
					if (debug)
						JS.log(this,getMetadata(ColumnMetadata.TITLE),key.keyType,key.localName,dataType,value);
				}
				catch (e:Error)
				{
					if (_lastError != e.message)
					{
						_lastError = e.message;
						JS.error(e);
					}
					//value = e;
				}
				finally
				{
					EquationColumnLib.currentRecordKey = prevKey;
				}
				
				// save value in cache
				if (value !== undefined)
					d2d_key_dataType_value.set(key, dataType, value);
				//trace('('+equation.value+')@"'+key+'" = '+value);
			}
			else if (value === UNDEFINED)
			{
				value = undefined;
			}
			else if (debug)
				JS.log('>',this,getMetadata(ColumnMetadata.TITLE),key.keyType,key.localName,dataType,value);
			
			if (dataType == IQualifiedKey)
			{
				if (!(value is IQualifiedKey))
				{
					if (!(value is String))
						value = StandardLib.asString(value);
					value = WeaveAPI.QKeyManager.getQKey(getMetadata(ColumnMetadata.DATA_TYPE), value);
				}
			}
			else if (dataType != null)
			{
				value = EquationColumnLib.cast(value, dataType);
			}
			
			return value;
		}
		
		private var _numberToStringFunction:Function = null;
		public function deriveStringFromNumber(number:Number):String
		{
			if (Weave.detectChange(deriveStringFromNumber, metadata))
			{
				try
				{
					_numberToStringFunction = StandardLib.formatNumber;
					var n2s:String = getMetadata(ColumnMetadata.STRING);
					if (n2s)
						_numberToStringFunction = JS.compile(n2s, ['number']);
				}
				catch (e:*)
				{
					errorHandler(e);
				}
			}
			
			if (_numberToStringFunction != null)
			{
				try
				{
					var string:String = _numberToStringFunction.apply(this, arguments);
					if (debug)
						JS.log(this, getMetadata(ColumnMetadata.TITLE), 'deriveStringFromNumber', number, string);
					return string;
				}
				catch (e:Error)
				{
					errorHandler(e);
				}
			}
			return '';
		}
	}
}
