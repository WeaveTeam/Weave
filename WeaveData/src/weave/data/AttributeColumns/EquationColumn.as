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

package weave.data.AttributeColumns
{
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectProxy;
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.compiler.CompiledConstant;
	import weave.compiler.Compiler;
	import weave.compiler.ICompiledObject;
	import weave.compiler.ProxyObject;
	import weave.compiler.StandardLib;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.core.UntypedLinkableVariable;
	import weave.data.QKeyManager;
	import weave.utils.ColumnUtils;
	import weave.utils.EquationColumnLib;
	
	/**
	 * This is a column of data derived from an equation with variables.
	 * 
	 * @author adufilie
	 */
	public class EquationColumn extends AbstractAttributeColumn
	{
		public static const compiler:Compiler = new Compiler();
		{ /** begin static code block **/
			compiler.includeLibraries(
				WeaveAPI,
				WeaveAPI.CSVParser,
				WeaveAPI.StatisticsCache,
				WeaveAPI.AttributeColumnCache,
				WeaveAPI.QKeyManager,
				EquationColumnLib
			);
			compiler.includeConstant("IQualifiedKey", IQualifiedKey);
		} /** end static code block **/
		

		public function EquationColumn()
		{
			setMetadata(AttributeColumnMetadata.TITLE, "Untitled Equation");
			//setMetadata(AttributeColumnMetadata.DATA_TYPE, DataTypes.NUMBER);
			equation.value = 'undefined';
		}
		
		/**
		 * This is all the keys in all the variables columns
		 */
		private var _allKeys:Array = null;
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
		 * This flag is set to true when the equation evaluates to a constant.
		 */
		private var _equationIsConstant:Boolean = false;
		/**
		 * This value is set to the result of the function when it compiles into a constant.
		 */
		private var _constantResult:* = undefined;
		/**
		 * This is a proxy object providing access to the variables.
		 */		
		private const _symbolTableProxy:ProxyObject = new ProxyObject(hasVariable, variableGetter, null);
		/**
		 * This is the last error thrown from the compiledEquation.
		 */		
		private var _lastError:String;
		/**
		 * This is true while code inside getValueFromKey is executing.
		 */		
		private var in_getValueFromKey:Boolean = false;
		/**
		 * This is a mapping from keys to cached data values.
		 */
		private var _equationResultCache:Dictionary = new Dictionary();
		private var _cacheTriggerCount:uint = 0;
		
		
		/**
		 * This is the equation that will be used in getValueFromKey().
		 */
		public const equation:LinkableString = newLinkableChild(this, LinkableString);
		/**
		 * This is a list of named variables made available to the compiled equation.
		 */
		public const variables:LinkableHashMap = newLinkableChild(this, LinkableHashMap);
		
		/**
		 * This holds the metadata for the column.
		 */
		public const metadata:UntypedLinkableVariable = newLinkableChild(this, UntypedLinkableVariable);
		
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
			
			var value:String = metadata.value ? metadata.value[propertyName] as String : null;
			if (value != null)
			{
				if (value.charAt(0) == '{' && value.charAt(value.length - 1) == '}')
				{
					try
					{
						var func:Function = compiler.compileToFunction(value, _symbolTableProxy, true);
						value = func.apply(this, arguments);
					}
					catch (e:Error)
					{
						if (_lastError != e.message)
						{
							_lastError = e.message;
							reportError(e);
						}
					}
				}
			}
			else
			{
				value = super.getMetadata(propertyName);
			}
			_cachedMetadata[propertyName] = value;
			return value;
		}

		/**
		 * This function will store an individual metadata value in the metadata linkable variable.
		 * @param propertyName
		 * @param value
		 */
		public function setMetadata(propertyName:String, value:String):void
		{
			value = StringUtil.trim(value);
			var _metadata:Object = metadata.value || {};
			_metadata[propertyName] = value;
			metadata.value = _metadata; // this triggers callbacks
		}
		
		/**
		 * This function gets called when dataType changes and sets _defaultDataType.
		 */
		private function handleDataTypeChange():void
		{
			var _dataType:String = getMetadata(AttributeColumnMetadata.DATA_TYPE);
			if (ObjectUtil.stringCompare(_dataType, DataTypes.GEOMETRY, true) == 0) // treat values as geometries
			{
				// we don't have code to cast as a geometry yet, so don't attempt it
				_defaultDataType = null;
			}
			else if (ObjectUtil.stringCompare(_dataType, DataTypes.NUMBER, true) == 0) // treat values as Numbers
			{
				_defaultDataType = Number;
			}
			else if (ObjectUtil.stringCompare(_dataType, DataTypes.STRING, true) == 0) // treat values as Strings
			{
				_defaultDataType = String;
			}
			else if (_dataType) // treat values as IQualifiedKeys
			{
				_defaultDataType = IQualifiedKey;
			}
			else
			{
				_defaultDataType = null;
			}
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
				_allKeys = ColumnUtils.getAllKeys(variables.getObjects(IAttributeColumn));
				_allKeysTriggerCount = variables.triggerCounter;
			}
			return _allKeys;
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return !StandardLib.isUndefined(getValueFromKey(key));
		}

		private function variableGetter(name:String):*
		{
			if (name == 'get')
				return variables.getObject as Function;
			return variables.getObject(name) || undefined;
		}
		
		private function hasVariable(name:String):Boolean
		{
			if (name == 'get')
				return true;
			return variables.getObject(name) != null;
		}
		
		
		/**
		 * @return The result of the compiled equation evaluated at the given record key.
		 * @see weave.api.data.IAttributeColumn
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (in_getValueFromKey && EquationColumnLib.currentRecordKey == key)
				return undefined; // recursively defined values are undefined
			
			// reset cached values if necessary
			if (_cacheTriggerCount != triggerCounter)
			{
				_cacheTriggerCount = triggerCounter;
				try
				{
					// check if the equation evaluates to a constant
					var compiledObject:ICompiledObject = compiler.compileToObject(equation.value);
					if (compiledObject is CompiledConstant)
					{
						// save the constant result of the function
						_equationIsConstant = true;
						_equationResultCache = null; // we don't need a cache
						_constantResult = (compiledObject as CompiledConstant).value;
					}
					else
					{
						// compile into a function
						compiledEquation = compiler.compileObjectToFunction(compiledObject, _symbolTableProxy, true, false, ['key', 'dataType']);
						_equationIsConstant = false;
						_equationResultCache = new Dictionary(); // create a new cache
						_constantResult = undefined;
					}
				}
				catch (e:Error)
				{
					// if compiling fails
					_equationIsConstant = true;
					_constantResult = undefined;
				}
			}
			
			var value:* = _constantResult;
			if (!_equationIsConstant)
			{
				// otherwise, use cached equation results
				value = _equationResultCache[key];
				// if the data value was not cached for this key yet, cache it now.
				if (value == undefined)
				{
					in_getValueFromKey = true; // prevent recursion caused by compiledEquation
					
					// prepare EquationColumnLib static parameter before calling the compiled equation
					EquationColumnLib.currentRecordKey = key;
					try
					{
						value = compiledEquation.apply(this, arguments);
					}
					catch (e:Error)
					{
						if (_lastError != e.message)
						{
							_lastError = e.message;
							reportError(e);
						}
						//value = e;
					}
					if (_equationResultCache)
						_equationResultCache[key] = value;
					//trace('('+equation.value+')@"'+key+'" = '+value);
					
					in_getValueFromKey = false; // prevent recursion caused by compiledEquation
				}
			}
			
			// if dataType not specified, use default type specified by this.dataType.value
			if (dataType == null)
				dataType = _defaultDataType;
			
			if (dataType == IQualifiedKey)
			{
				if (!(value is IQualifiedKey))
				{
					if (!(value is String))
						value = StandardLib.asString(value);
					value = WeaveAPI.QKeyManager.getQKey(getMetadata(AttributeColumnMetadata.DATA_TYPE), value);
				}
			}
			else if (dataType != null)
			{
				value = EquationColumnLib.cast(value, dataType);
			}
			
			return value;
		}

		
		//---------------------------------
		// backwards compatibility
		[Deprecated(replacement="metadata")] public function set columnTitle(value:String):void { setMetadata(AttributeColumnMetadata.TITLE, value); }
	}
}
