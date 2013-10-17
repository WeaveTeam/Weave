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
	
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.compiler.CompiledConstant;
	import weave.compiler.Compiler;
	import weave.compiler.ICompiledObject;
	import weave.compiler.ProxyObject;
	import weave.compiler.StandardLib;
	import weave.core.LinkableFunction;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.core.UntypedLinkableVariable;
	import weave.utils.ColumnUtils;
	import weave.utils.Dictionary2D;
	import weave.utils.EquationColumnLib;
	
	/**
	 * This is a column of data derived from an equation with variables.
	 * 
	 * @author adufilie
	 */
	public class EquationColumn extends AbstractAttributeColumn implements IPrimitiveColumn
	{
		public static var debug:Boolean = false;
		
		public static const compiler:Compiler = new Compiler();
		/** begin static code block **/
		compiler.includeLibraries(
			WeaveAPI,
			WeaveAPI.CSVParser,
			WeaveAPI.StatisticsCache,
			WeaveAPI.AttributeColumnCache,
			WeaveAPI.QKeyManager,
			EquationColumnLib,
			IQualifiedKey
		);
		/** end static code block **/
		

		public function EquationColumn()
		{
			getCallbackCollection(LinkableFunction.macroLibraries).addImmediateCallback(this, equation.triggerCallbacks, false, true);
			getCallbackCollection(LinkableFunction.macros).addImmediateCallback(this, equation.triggerCallbacks, false, true);
			
			setMetadata(ColumnMetadata.TITLE, "Untitled Equation");
			//setMetadata(AttributeColumnMetadata.DATA_TYPE, DataTypes.NUMBER);
			
			variables.childListCallbacks.addImmediateCallback(this, handleVariableListChange);
		}
		
		private function handleVariableListChange():void
		{
			// make callbacks trigger when statistics change for listed variables
			var newColumn:IAttributeColumn = variables.childListCallbacks.lastObjectAdded as IAttributeColumn;
			if (newColumn)
				getCallbackCollection(WeaveAPI.StatisticsCache.getColumnStatistics(newColumn)).addImmediateCallback(this, triggerCallbacks);
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
		 * This is a mapping from keys to cached data values.
		 */
		private const _equationResultCache:Dictionary2D = new Dictionary2D();
		/**
		 * This is used to determine when to clear the cache.
		 */		
		private var _cacheTriggerCount:uint = 0;
		/**
		 * This is used as a placeholder in _equationResultCache.
		 */		
		private static const UNDEFINED:Object = {};
		
		
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
						var func:Function = compiler.compileToFunction(value, _symbolTableProxy, errorHandler);
						value = func.apply(this, arguments);
					}
					catch (e:*)
					{
						errorHandler(e);
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
		
		private function errorHandler(e:*):void
		{
			var str:String = e is Error ? e.message : String(e);
			if (_lastError != str)
			{
				_lastError = str;
				reportError(e);
			}
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
		private function cacheDefaultDataType():void
		{
			var _dataType:String = getMetadata(ColumnMetadata.DATA_TYPE);
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
				_allKeys = null;
				_allKeysTriggerCount = variables.triggerCounter; // prevent infinite recursion
				
				_allKeys = ColumnUtils.getAllKeys(variables.getObjects(IAttributeColumn));
			}
			return _allKeys || [];
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
			return variables.getObject(name)
				|| LinkableFunction.evaluateMacro(name)
				|| undefined;
		}
		
		private function hasVariable(name:String):Boolean
		{
			if (name == 'get')
				return true;
			return variables.getObject(name) != null
				|| LinkableFunction.macros.getObject(name) != null;
		}
		
		private function handleChange():void
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
					_equationResultCache.dictionary = null; // we don't need a cache
					_constantResult = (compiledObject as CompiledConstant).value;
				}
				else
				{
					// compile into a function
					compiledEquation = compiler.compileObjectToFunction(compiledObject, _symbolTableProxy, errorHandler, false, ['key', 'dataType']);
					_equationIsConstant = false;
					_equationResultCache.dictionary = new Dictionary(); // create a new cache
					_constantResult = undefined;
				}
			}
			catch (e:Error)
			{
				// if compiling fails
				_equationIsConstant = true;
				_constantResult = undefined;
			}
			cacheDefaultDataType();
			
			try
			{
				_numberToStringFunction = StandardLib.formatNumber;
				var n2s:String = getMetadata(ColumnMetadata.STRING);
				if (n2s)
					_numberToStringFunction = compiler.compileToFunction(n2s, _symbolTableProxy, errorHandler, false, ['number']);
			}
			catch (e:*)
			{
				errorHandler(e);
			}
		}
		
		/**
		 * @return The result of the compiled equation evaluated at the given record key.
		 * @see weave.api.data.IAttributeColumn
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			// reset cached values if necessary
			if (_cacheTriggerCount != triggerCounter)
				handleChange();
			
			// if dataType not specified, use default type specified in metadata
			if (dataType == null)
				dataType = _defaultDataType;
			
			var value:* = _constantResult;
			if (!_equationIsConstant)
			{
				// check the cache
				value = _equationResultCache.get(key, dataType);
				// define cached value if missing
				if (value === undefined)
				{
					// prevent recursion caused by compiledEquation
					_equationResultCache.set(key, dataType, UNDEFINED);
					
					// prepare EquationColumnLib static parameter before calling the compiled equation
					EquationColumnLib.currentRecordKey = key;
					try
					{
						value = compiledEquation.apply(this, arguments);
						if (debug)
							trace(debugId(this),getMetadata(ColumnMetadata.TITLE),key.keyType,key.localName,dataType,value);
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
					
					// save value in cache
					if (value !== undefined)
						_equationResultCache.set(key, dataType, value);
					//trace('('+equation.value+')@"'+key+'" = '+value);
				}
				else if (value === UNDEFINED)
				{
					value = undefined;
				}
				else if (debug)
					trace('>',debugId(this),getMetadata(ColumnMetadata.TITLE),key.keyType,key.localName,dataType,value);
			}
			
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
			// reset cached values if necessary
			if (_cacheTriggerCount != triggerCounter)
				handleChange();
			
			if (_numberToStringFunction != null)
			{
				try
				{
					var string:String = _numberToStringFunction.apply(this, arguments);
					if (debug)
						trace(debugId(this),getMetadata(ColumnMetadata.TITLE),'deriveStringFromNumber',number,string);
					return string;
				}
				catch (e:Error)
				{
					errorHandler(e);
				}
			}
			return '';
		}

		override public function toString():String
		{
			return StringUtil.substitute('{0};"{1}";({2})', debugId(this), getMetadata(ColumnMetadata.TITLE), equation.value);
		}
		
		//---------------------------------
		// backwards compatibility
		[Deprecated(replacement="metadata")] public function set columnTitle(value:String):void { setMetadata(ColumnMetadata.TITLE, value); }
	}
}
