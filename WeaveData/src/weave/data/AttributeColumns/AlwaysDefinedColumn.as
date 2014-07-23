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
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.UntypedLinkableVariable;
	import weave.utils.EquationColumnLib;
	
	/**
	 * AlwaysDefinedColumn
	 * 
	 * @author adufilie
	 */
	public class AlwaysDefinedColumn extends ExtendedDynamicColumn
	{
		public function AlwaysDefinedColumn(defaultValue:* = undefined, defaultValueVerifier:Function = null)
		{
			super();
			_defaultValue = new UntypedLinkableVariable(defaultValue, defaultValueVerifier);
			registerLinkableChild(this, _defaultValue, handleDefaultValueChange);
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return true;
		}
		
		/**
		 * This sessioned property contains the default value to be returned
		 * when the referenced column does not define a value for a given key.
		 */
		private var _defaultValue:UntypedLinkableVariable;
		public function get defaultValue():UntypedLinkableVariable
		{
			return _defaultValue;
		}
		private function handleDefaultValueChange():void
		{
			_cachedDefaultValue = defaultValue.value;
		}
		private var _cachedDefaultValue:*;
		
		/**
		 * getValueFromKey
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var value:* = internalDynamicColumn.getValueFromKey(key, dataType);

			if (StandardLib.isUndefined(value))
			{
				value = _cachedDefaultValue;
				if (dataType != null)
					value = EquationColumnLib.cast(value, dataType);
			}
			
			return value;
		}
	}
}
