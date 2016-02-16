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

package weavejs.data.key
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.IDisposableObject;
	import weavejs.api.data.IKeySet;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.CallbackCollection;
	import weavejs.util.DebugUtils;
	import weavejs.util.JS;
	
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
		public function KeySetUnion(keyInclusionLogic:/*/(key:IQualifiedKey)=>boolean/*/Function = null)
		{
			_keyInclusionLogic = keyInclusionLogic;
			
			if (debug)
				Weave.getCallbacks(this).addImmediateCallback(this, _firstCallback);
		}
		
		private function _firstCallback():void { DebugUtils.debugTrace(this,'trigger',keys.length,'keys'); }
		
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
				Weave.getCallbacks(keySet).addDisposeCallback(this, asyncStart);
				Weave.getCallbacks(keySet).addImmediateCallback(this, asyncStart, true);
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
			return map_key.get(key) === true;
		}
		
		private var _keySets:Array = []; // Array of IKeySet
		private var _allKeys:Array = []; // Array of IQualifiedKey
		private var map_key:Object = new JS.WeakMap(); // IQualifiedKey -> Boolean
		
		/**
		 * Use this to check asynchronous task busy status.  This is kept separate because if we report busy status we need to
		 * trigger callbacks when an asynchronous task completes, but we don't want to trigger KeySetUnion callbacks when nothing
		 * changes as a result of completing the asynchronous task.
		 */
		public const busyStatus:ICallbackCollection = Weave.disposableChild(this, CallbackCollection); // separate owner for the async task to avoid affecting our busy status
		
		private var _asyncKeys:Array; // keys from current key set
		private var _asyncKeySetIndex:int; // index of current key set
		private var _asyncKeyIndex:int; // index of current key
		private var _prevCompareCounter:int; // keeps track of how many new keys are found in the old keys list
		private var _async_map_key:Object; // for comparing to new keys lookup
		private var _asyncAllKeys:Array; // new allKeys array in progress
		
		private function asyncStart():void
		{
			// remove disposed key sets
			for (var i:int = _keySets.length; i--;)
				if (Weave.wasDisposed(_keySets[i]))
					_keySets.splice(i, 1);
			
			// restart async task
			_prevCompareCounter = 0;
			_asyncAllKeys = [];
			_async_map_key = new JS.WeakMap();
			_asyncKeys = null;
			_asyncKeySetIndex = 0;
			_asyncKeyIndex = 0;
			// high priority because all visualizations depend on key sets
			WeaveAPI.Scheduler.startTask(busyStatus, asyncIterate, WeaveAPI.TASK_PRIORITY_HIGH, asyncComplete, Weave.lang("Computing the union of {0} key sets", _keySets.length));
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
				
				for (; _asyncKeys && _asyncKeyIndex < _asyncKeys.length; _asyncKeyIndex++)
				{
					if (JS.now() > stopTime)
						return (_asyncKeySetIndex + _asyncKeyIndex / _asyncKeys.length) / _keySets.length;
					
					var key:IQualifiedKey = _asyncKeys[_asyncKeyIndex] as IQualifiedKey;
					if (!_async_map_key.has(key)) // if we haven't seen this key yet
					{
						var includeKey:Boolean = (_keyInclusionLogic == null) ? true : _keyInclusionLogic(key);
						_async_map_key.set(key, includeKey);
						
						if (includeKey)
						{
							_asyncAllKeys.push(key);
							
							// keep track of how many keys we saw both previously and currently
							if (map_key.get(key) === true)
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
			if (_allKeys.length != _asyncAllKeys.length || _allKeys.length != _prevCompareCounter)
			{
				_allKeys = _asyncAllKeys;
				map_key = _async_map_key;
				Weave.getCallbacks(this).triggerCallbacks();
			}
			
			busyStatus.triggerCallbacks();
		}
		
		public function dispose():void
		{
			_keySets = null;
			_allKeys = null;
			map_key = null;
			_async_map_key = null;
		}
	}
}
