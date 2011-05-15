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

package org.oicweave.data.KeySets
{
	import org.oicweave.api.core.ICallbackCollection;
	import org.oicweave.api.core.ILinkableObject;
	import org.oicweave.api.data.IKeyFilter;
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.disposeObjects;
	import org.oicweave.api.getCallbackCollection;
	import org.oicweave.api.newLinkableChild;
	import org.oicweave.core.LinkableBoolean;
	import org.oicweave.core.LinkableString;
	
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
		[Deprecated] public function get sessionedKeyType():LinkableString { return handleDeprecatedSessionedProperty('sessionedKeyType'); }
		[Deprecated(replacement="included")] public function get includedKeys():LinkableString { return handleDeprecatedSessionedProperty('includedKeys'); }
		[Deprecated(replacement="excluded")] public function get excludedKeys():LinkableString { return handleDeprecatedSessionedProperty('excludedKeys'); }
		private var _deprecatedProperties:Object = null;
		private function handleDeprecatedSessionedProperty(propertyName:String):LinkableString
		{
			if (_deprecatedProperties == null)
			{
				_deprecatedProperties = {};
				var callbackCollection:ICallbackCollection = getCallbackCollection(this);
				var applyDeprecatedSessionState:Function = function():void
				{
					// make sure this callback only runs once
					callbackCollection.removeCallback(applyDeprecatedSessionState);
					// get the values from the deprecated properties
					var state:Object = {};
					for (var name:String in _deprecatedProperties)
					{
						state[name] = (_deprecatedProperties[name] as LinkableString).value;
						// dispose of the deprecated properties
						disposeObjects(_deprecatedProperties[name]);
					}
					// apply the deprecated session state to 'included' and 'excluded' KeySets
					state.sessionedKeys = state.includedKeys;
					included.setSessionState(state);
					state.sessionedKeys = state.excludedKeys;
					excluded.setSessionState(state);
				};
				callbackCollection.addImmediateCallback(this, applyDeprecatedSessionState);
			}
			if (_deprecatedProperties[propertyName] == undefined)
				_deprecatedProperties[propertyName] = newLinkableChild(this, LinkableString);
			return _deprecatedProperties[propertyName] as LinkableString;
		}
	}
}
