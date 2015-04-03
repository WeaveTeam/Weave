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

package weave.data.KeySets
{
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	
	/**
	 * This class is used to include and exclude IQualifiedKeys from a set.
	 * 
	 * @author adufilie
	 */
	public class KeyFilter implements IKeyFilter, ILinkableObject
	{
		public function KeyFilter()
		{
			includeMissingKeys.value = false;
			includeMissingKeyTypes.value = true;
			filters.childListCallbacks.addImmediateCallback(this, cacheValues);
		}
		
		// option to include missing keys or not
		public const includeMissingKeys:LinkableBoolean = newLinkableChild(this, LinkableBoolean, cacheValues);
		public const includeMissingKeyTypes:LinkableBoolean = newLinkableChild(this, LinkableBoolean, cacheValues);
		
		public const included:KeySet = newLinkableChild(this, KeySet, handleIncludeChange);
		public const excluded:KeySet = newLinkableChild(this, KeySet, handleExcludeChange);
		
		public const filters:ILinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IKeyFilter));
		
		private var _includeMissingKeys:Boolean;
		private var _includeMissingKeyTypes:Boolean;
		private var _filters:Array;
		private function cacheValues():void
		{
			_includeMissingKeys = includeMissingKeys.value;
			_includeMissingKeyTypes = includeMissingKeyTypes.value;
			_filters = filters.getObjects();
		}

		/**
		 * This replaces the included and excluded keys in the filter with the parameters specified.
		 */
		public function replaceKeys(includeMissingKeys:Boolean, includeMissingKeyTypes:Boolean, includeKeys:Array = null, excludeKeys:Array = null):void
		{
			getCallbackCollection(this).delayCallbacks();
			
			this.includeMissingKeys.value = includeMissingKeys;
			this.includeMissingKeyTypes.value = includeMissingKeyTypes;

			if (includeKeys)
				included.replaceKeys(includeKeys);
			else
				included.clearKeys();

			if (excludeKeys)
				excluded.replaceKeys(excludeKeys);
			else
				excluded.clearKeys();
			
			getCallbackCollection(this).resumeCallbacks();
		}

		// adds keys to include list
		public function includeKeys(keys:Array):void
		{
			included.addKeys(keys);
		}
		
		// adds keys to exclude list
		public function excludeKeys(keys:Array):void
		{
			excluded.addKeys(keys);
		}
		
		private var _includedKeyTypeMap:Object = new Object();
		private var _excludedKeyTypeMap:Object = new Object();
		
		// removes keys from exclude list that were just added to include list
		private function handleIncludeChange():void
		{
			var includedKeys:Array = included.keys;
			_includedKeyTypeMap = new Object();
			for each (var key:IQualifiedKey in includedKeys)
				_includedKeyTypeMap[key.keyType] = true;
			
			excluded.removeKeys(includedKeys);
		}

		// removes keys from include list that were just added to exclude list
		private function handleExcludeChange():void
		{
			var excludedKeys:Array = excluded.keys;
			_excludedKeyTypeMap = new Object();
			for each (var key:IQualifiedKey in excludedKeys)
				_excludedKeyTypeMap[key.keyType] = true;
			
			included.removeKeys(excludedKeys);
		}
		
		/**
		 * @param key A key to test.
		 * @return true if this filter includes the key, false if the filter excludes it.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			for each (var filter:IKeyFilter in _filters)
				if (!filter.containsKey(key))
					return false;
			
			if (_includeMissingKeys || (_includeMissingKeyTypes && !_includedKeyTypeMap[key.keyType]))
			{
				if (excluded.containsKey(key))
					return false;
				if (!_includeMissingKeyTypes && _excludedKeyTypeMap[key.keyType])
					return false;
				return true;
			}
			else // exclude missing keys
			{
				if (included.containsKey(key))
					return true;
				// if includeMissingKeyTypes and keyType is missing
				if (_includeMissingKeyTypes && !_includedKeyTypeMap[key.keyType] && !_excludedKeyTypeMap[key.keyType])
					return true;
				return false;
			}
		}
		
		//----------------------------------------------------------
		// backwards compatibility 0.9.6
		[Deprecated] public function set sessionedKeyType(value:String):void
		{
			handleDeprecatedSessionedProperty('sessionedKeyType', value);
		}
		[Deprecated(replacement="included")] public function set includedKeys(value:String):void
		{
			handleDeprecatedSessionedProperty('includedKeys', value);
		}
		[Deprecated(replacement="excluded")] public function set excludedKeys(value:String):void
		{
			handleDeprecatedSessionedProperty('excludedKeys', value);
		}
		private function handleDeprecatedSessionedProperty(propertyName:String, value:String):void
		{
			if (_deprecatedState == null)
			{
				_deprecatedState = {};
				WeaveAPI.StageUtils.callLater(this, _applyDeprecatedSessionState);
			}
			_deprecatedState[propertyName] = value;
		}
		private var _deprecatedState:Object = null;
		private function _applyDeprecatedSessionState():void
		{
			_deprecatedState.sessionedKeys = _deprecatedState.includedKeys;
			included.setSessionState(_deprecatedState);
			_deprecatedState.sessionedKeys = _deprecatedState.excludedKeys;
			excluded.setSessionState(_deprecatedState);
		}
	}
}
