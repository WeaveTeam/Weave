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

package weave.data.KeySets
{
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObjects;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableString;
	import weave.core.StageUtils;
	
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
		}
		
		// option to include missing keys or not
		public const includeMissingKeys:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const includeMissingKeyTypes:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		
		public const included:KeySet = newLinkableChild(this, KeySet, handleIncludeChange);
		public const excluded:KeySet = newLinkableChild(this, KeySet, handleExcludeChange);

		/**
		 * This replaces the included and excluded keys in the filter with the parameters specified.
		 */
		public function replaceKeys(includeMissingKeys:Boolean, includeMissingKeyTypes:Boolean, includeKeys:Array = null, excludeKeys:Array = null):void
		{
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
			if (includeMissingKeys.value || (includeMissingKeyTypes.value && !_includedKeyTypeMap[key.keyType]))
			{
				if (excluded.containsKey(key))
					return false;
				if (!includeMissingKeyTypes.value && _excludedKeyTypeMap[key.keyType])
					return false;
				return true;
			}
			else // exclude missing keys
			{
				if (included.containsKey(key))
					return true;
				// if includeMissingKeyTypes and keyType is missing
				if (includeMissingKeyTypes.value && !_includedKeyTypeMap[key.keyType] && !_excludedKeyTypeMap[key.keyType])
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
				StageUtils.callLater(this, _applyDeprecatedSessionState, null, false);
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
