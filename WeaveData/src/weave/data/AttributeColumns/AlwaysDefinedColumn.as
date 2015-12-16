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

package weave.data.AttributeColumns
{
	import flash.utils.Dictionary;
	
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
		
		private var _cache_type_key:Dictionary = new Dictionary(true);
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
				
				if (StandardLib.isUndefined(value))
				{
					value = _cachedDefaultValue;
					if (dataType != null)
						value = EquationColumnLib.cast(value, dataType);
				}
				
				return value;
			}
			
			if (triggerCounter != _cacheCounter)
			{
				_cacheCounter = triggerCounter;
				_cache_type_key = new Dictionary(true);
			}
			var _cache:Dictionary = _cache_type_key[dataType];
			if (!_cache)
				_cache_type_key[dataType] = _cache = new Dictionary(true);
			
			value = _cache[key];
			if (value === undefined)
			{
				value = internalDynamicColumn.getValueFromKey(key, dataType);
				if (StandardLib.isUndefined(value))
				{
					value = _cachedDefaultValue;
					if (dataType != null)
						value = EquationColumnLib.cast(value, dataType);
				}
				
				_cache[key] = value === undefined ? UNDEFINED : value;
			}
			return value === UNDEFINED ? undefined : value;
		}
	}
}
