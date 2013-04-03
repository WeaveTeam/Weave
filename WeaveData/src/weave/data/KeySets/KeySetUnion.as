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
	import flash.utils.getTimer;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.objectWasDisposed;
	import weave.core.CallbackCollection;
	
	/**
	 * This key set is the union of several other key sets.  It has no session state.
	 * 
	 * @author adufilie
	 */
	public class KeySetUnion implements IKeySet, IDisposableObject
	{
		public static var debug:Boolean = false;
		
		/**
		 * @param keyInclusionLogic A function that accepts an IQualifiedKey and returns true or false.
		 */		
		public function KeySetUnion(keyInclusionLogic:Function = null)
		{
			_keyInclusionLogic = keyInclusionLogic;
			
			if (debug)
				getCallbackCollection(this).addImmediateCallback(this, _firstCallback);
		}
		
		private function _firstCallback():void { debugTrace(this,'trigger',keys.length,'keys'); }
		
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
				getCallbackCollection(keySet).addDisposeCallback(this, asyncStart);
				getCallbackCollection(keySet).addImmediateCallback(this, asyncStart, true);
			}
		}
		
		/**
		 * This is a list of the IQualifiedKey objects that define the key set.
		 */
		public function get keys():Array
		{
			return _allKeys;
		}

		/**
		 * @param key A IQualifiedKey object to check.
		 * @return true if the given key is included in the set.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return _keyLookup[key] === true;
		}
		
		private var _keySets:Array = []; // Array of IKeySet
		private var _allKeys:Array = []; // Array of IQualifiedKey
		private var _keyLookup:Dictionary = new Dictionary(true); // IQualifiedKey -> Boolean
		
		/*
		* Catch-22:
		*     We want to report busy status when computing union, but we don't want to trigger
		*     union callbacks if nothing changes as a result of the async task.  However,
		*     if we report busy status, we should be triggering callbacks when the task completes.
		*     For now, we don't report busy status.
		*/
		private var _asyncOwner:ILinkableObject = newDisposableChild(this, CallbackCollection); // separate owner for the async task to avoid affecting our busy status
		private var _asyncKeys:Array; // keys from current key set
		private var _asyncKeySetIndex:int; // index of current key set
		private var _asyncKeyIndex:int; // index of current key
		private var _prevCompareCounter:int; // keeps track of how many new keys are found in the old keys list
		private var _newKeyLookup:Dictionary; // for comparing to new keys lookup
		private var _newKeys:Array; // new allKeys array in progress
		
		private function asyncStart():void
		{
			// remove disposed key sets
			for (var i:int = _keySets.length; i--;)
				if (objectWasDisposed(_keySets[i]))
					_keySets.splice(i, 1);
			
			// restart async task
			_prevCompareCounter = 0;
			_newKeys = [];
			_newKeyLookup = new Dictionary(true);
			_asyncKeys = null;
			_asyncKeySetIndex = 0;
			_asyncKeyIndex = 0;
			WeaveAPI.StageUtils.startTask(_asyncOwner, asyncIterate, WeaveAPI.TASK_PRIORITY_BUILDING, asyncComplete);
		}
		
		private function asyncIterate(stopTime:int):Number
		{
			for (; _asyncKeySetIndex < _keySets.length; _asyncKeySetIndex++)
			{
				if (_asyncKeys == null)
				{
					_asyncKeys = (_keySets[_asyncKeySetIndex] as IKeySet).keys;
					_asyncKeyIndex = 0;
				}
				
				for (; _asyncKeyIndex < _asyncKeys.length; _asyncKeyIndex++)
				{
					if (getTimer() > stopTime)
						return (_asyncKeySetIndex + _asyncKeyIndex / _asyncKeys.length) / _keySets.length;
					
					var key:IQualifiedKey = _asyncKeys[_asyncKeyIndex] as IQualifiedKey;
					if (_newKeyLookup[key] === undefined) // if we haven't seen this key yet
					{
						var includeKey:Boolean = (_keyInclusionLogic == null) ? true : _keyInclusionLogic(key);
						_newKeyLookup[key] = includeKey;
						
						if (includeKey)
						{
							_newKeys.push(key);
							
							// keep track of how many keys we saw both previously and currently
							if (_keyLookup[key] === true)
								_prevCompareCounter++;
						}
					}
				}

				_asyncKeys = null;
			}
			return 1; // avoids division by zero
		}
		
		private function asyncComplete():void
		{
			// detect change
			if (_allKeys.length != _newKeys.length || _allKeys.length != _prevCompareCounter)
			{
				_allKeys = _newKeys;
				_keyLookup = _newKeyLookup;
				getCallbackCollection(this).triggerCallbacks();
			}
			
			getCallbackCollection(_asyncOwner).triggerCallbacks();
		}
		
		public function dispose():void
		{
			_keySets = null;
			_allKeys = null;
			_keyLookup = null;
			_newKeyLookup = null;
		}
	}
}
