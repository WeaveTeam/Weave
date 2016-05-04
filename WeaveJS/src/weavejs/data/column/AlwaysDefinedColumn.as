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
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableVariable;
	import weavejs.data.EquationColumnLib;
	import weavejs.util.Dictionary2D;
	import weavejs.util.StandardLib;
	
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
			_defaultValue = new LinkableVariable(null, defaultValueVerifier, defaultValue);
			Weave.linkableChild(this, _defaultValue, handleDefaultValueChange);
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
		private var _defaultValue:LinkableVariable;
		public function get defaultValue():LinkableVariable
		{
			return _defaultValue;
		}
		private function handleDefaultValueChange():void
		{
			_cachedDefaultValue = defaultValue.state;
		}
		private var _cachedDefaultValue:*;
		
		private var d2d_type_key:Dictionary2D = new Dictionary2D(true, true);
		private var _cacheCounter:int = 0;
		private static const UNDEFINED:Object = {};
		
		/**
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (!dataType)
				dataType = Array;
			if (!DynamicColumn.cache)
			{
				var value:* = internalDynamicColumn.getValueFromKey(key, dataType);
				
				if (StandardLib.isUndefined(value, true))
					value = EquationColumnLib.cast(_cachedDefaultValue, dataType);
				
				return value;
			}
			
			if (triggerCounter != _cacheCounter)
			{
				_cacheCounter = triggerCounter;
				d2d_type_key = new Dictionary2D(true, true);
			}
			
			value = d2d_type_key.get(dataType, key);
			if (value === undefined)
			{
				value = internalDynamicColumn.getValueFromKey(key, dataType);
				
				if (StandardLib.isUndefined(value, true))
					value = EquationColumnLib.cast(_cachedDefaultValue, dataType);
				
				d2d_type_key.set(dataType, key, value === undefined ? UNDEFINED : value);
			}
			return value === UNDEFINED ? undefined : value;
		}
	}
}
