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
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.compiler.BooleanLib;
	import weave.compiler.CompiledConstant;
	import weave.compiler.EquationCompiler;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	
	/**
	 * This is a column of data derived from an equation with variables.
	 * 
	 * @author adufilie
	 */
	public class EquationColumn extends AbstractAttributeColumn
	{
		{ /** begin static code block **/
			EquationCompiler.includeLibraries(
				WeaveAPI.StatisticsCache,
				WeaveAPI.CSVParser,
				WeaveAPI.QKeyManager,
				EquationColumnLib
			);
		} /** end static code block **/

		public function EquationColumn()
		{
			init();
		}
		private function init():void
		{
			columnTitle.value = "Equation Column";
			equation.value = 'undefined';
			variables.childListCallbacks.addImmediateCallback(this, handleVariablesListChange);
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == AttributeColumnMetadata.TITLE)
				return columnTitle.value;
			if (propertyName == AttributeColumnMetadata.UNIT)
				return unitType.value;
			return super.getMetadata(propertyName);
		}

		/**
		 * This is a title for the column.
		 */
		public const columnTitle:LinkableString = newLinkableChild(this, LinkableString);
		/**
		 * This is the column to get keys from.
		 */
		public const keyColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
		/**
		 * This is the equation that will be used in getValueFromKey().
		 */
		public const equation:LinkableString = newLinkableChild(this, LinkableString, handleEquationChange);
		/**
		 * This is a list of named variables made available to the compiled equation.
		 */
		public const variables:LinkableHashMap = newLinkableChild(this, LinkableHashMap, handleVariablesChange);

		/**
		 * This is the unit of the data values returned by the equation.
		 */
		public const unitType:LinkableString = newLinkableChild(this, LinkableString);
		
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
		 * This function gets called when the equation changes.
		 */
		private function handleEquationChange():void
		{
			//trace(equation.value, "handleEquationChange");
			// clear the cached data
			_equationResultCache = null;

			//todo: error checking?

			try
			{
				// set default values in case an error is thrown
				compiledEquation = null;
				_equationIsConstant = true;
				_constantResult = undefined;
				
				// check if the equation evaluates to a constant
				var constant:CompiledConstant = EquationCompiler.compileEquationToObject(equation.value, null, true) as CompiledConstant;
				if (constant)
				{
					// save the constant result of the function
					_equationIsConstant = true;
					_constantResult = constant.value;
				}
				else
				{
					// compile into a function
					compiledEquation = EquationCompiler.compileEquation(equation.value, variables.getObject);
					_equationIsConstant = false;
				}
			}
			catch (e:Error)
			{
				// It will not hurt anything if this fails.
			}
		}

		/**
		 * This is the column to get keys and keyType from if keyColumn is undefined.
		 */
		private var _columnToGetKeysFrom:IAttributeColumn = null;
		
		/**
		 * @return The keys associated with this EquationColumn.
		 */
		override public function get keys():Array
		{
			if (keyColumn.internalColumn)
				return keyColumn.keys;
			return _columnToGetKeysFrom ? _columnToGetKeysFrom.keys : [];
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return !BooleanLib.isUndefined(getValueFromKey(key));
		}
		
		private function handleVariablesListChange():void
		{
			if (variables.childListCallbacks.lastObjectRemoved == _columnToGetKeysFrom)
				_columnToGetKeysFrom = null;
			if (_columnToGetKeysFrom == null)
			{
				// save a pointer to the first column in the variables list (to get keys from)
				var columns:Array = variables.getObjects(IAttributeColumn);
				if (columns.length > 0)
					_columnToGetKeysFrom = (columns[0] as IAttributeColumn);
			}
		}

		/**
		 * This function gets called when the variables change.
		 */
		private function handleVariablesChange():void
		{
			//trace(equation.value, "handleVariablesChange");
			// clear the cached data
			_equationResultCache = null;

			handleVariablesListChange();
		}
		
		/**
		 * @return The result of the compiled equation evaluated at the given record key.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var value:*;
			if (_equationIsConstant)
			{
				// if the equation evaluated to a constant, just use the constant value
				value = _constantResult;
			}
			else
			{
				// otherwise, use cached equation results
				if (_equationResultCache == null)
					_equationResultCache = new Dictionary();
				value = _equationResultCache[key];
				// if the data value was not cached for this key yet, cache it now.
				if (value == undefined)
				{
					// prepare EquationColumnLib static parameter before calling the compiled equation
					EquationColumnLib.currentRecordKey = key;
					try
					{
						value = compiledEquation();
					}
					catch (e:Error)
					{
						trace(e.message);
					}
					_equationResultCache[key] = value;
					//trace('('+equation.value+')@"'+key+'" = '+value);
				}
			}
			if (dataType != null)
				value = EquationColumnLib.cast(value, dataType);
			return value;
		}

		/**
		 * This is a mapping from keys to cached data values.
		 */
		private var _equationResultCache:Dictionary = new Dictionary();
	}
}
