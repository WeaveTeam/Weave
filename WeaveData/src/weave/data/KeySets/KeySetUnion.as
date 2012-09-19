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
	import flash.utils.Dictionary;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;
	
	/**
	 * This key set is the union of several other key sets.  It has no session state.
	 * 
	 * @author adufilie
	 */
	public class KeySetUnion implements IKeySet, IDisposableObject
	{
		/**
		 * @param keyInclusionLogic A function that accepts an IQualifiedKey and returns true or false.
		 */		
		public function KeySetUnion(keyInclusionLogic:Function = null)
		{
			_keyInclusionLogic = keyInclusionLogic;
		}
		
		/**
		 * This will be used to determine whether or not to include a key.
		 */		
		private var _keyInclusionLogic:Function = null;
		
		/**
		 * This will add an IKeySet as a dependency and include its keys in the union.
		 * @param keySet
		 */
		public function addKeySetDependency(keySet:IKeySet):void
		{
			if (_keySets.indexOf(keySet) < 0)
			{
				_keySets.push(keySet);
				registerLinkableChild(this, keySet);
				getCallbackCollection(keySet).addDisposeCallback(this, getCallbackCollection(this).triggerCallbacks);
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/**
		 * This is a list of the IQualifiedKey objects that define the key set.
		 */
		public function get keys():Array
		{
			_validate();
			return _allKeys;
		}

		/**
		 * @param key A IQualifiedKey object to check.
		 * @return true if the given key is included in the set.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			_validate();
			return _keyLookup[key] === true;
		}
		
		private var _keySets:Array = [];
		private var _allKeys:Array;
		private var _keyLookup:Dictionary;
		
		private function _validate():void
		{
			if (detectLinkableObjectChange(_validate, this))
			{
				_allKeys = [];
				_keyLookup = new Dictionary(true);
				for (var i:int = 0; i < _keySets.length; i++)
				{
					var keys:Array = (_keySets[i] as IKeySet).keys;
					for (var j:int = 0; j < keys.length; j++)
					{
						var key:IQualifiedKey = keys[j] as IQualifiedKey;
						if (_keyLookup[key] === undefined)
						{
							var includeKey:Boolean = (_keyInclusionLogic == null) ? true : _keyInclusionLogic(key);
							_keyLookup[key] = includeKey;
							if (includeKey)
								_allKeys.push(key);
						}
					}
				}
			}
		}
		
		public function dispose():void
		{
			_allKeys = null;
			_keyLookup = null;
		}
	}
}
