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
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IColumnStatistics;
	import weavejs.api.data.IKeySet;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.CallbackCollection;
	import weavejs.util.StandardLib;
	
	/**
	 * This provides the keys from an existing IKeySet in a sorted order.
	 * Callbacks will trigger when the sorted result changes.
	 * 
	 * @author adufilie
	 */
	public class SortedKeySet implements IKeySet
	{
		/**
		 * @param keySet An IKeySet to sort.
		 * @param sortCopyFunction A function that accepts an Array of IQualifiedKeys and returns a new, sorted copy.
		 * @param dependencies A list of ILinkableObjects that affect the result of the compare function.
		 *                     If any IAttributeColumns are provided, the corresponding IColumnStatistics will also
		 *                     be added as dependencies.
		 */		
		public function SortedKeySet(keySet:IKeySet, sortCopyFunction:Function = null, dependencies:Array = null)
		{
			_keySet = keySet;
			_sortCopyFunction = sortCopyFunction as Function || QKeyManager.keySortCopy as Function;
			
			for each (var object:ILinkableObject in dependencies)
			{
				Weave.linkableChild(_dependencies, object);
				if (object is IAttributeColumn)
				{
					var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(object as IAttributeColumn);
					Weave.linkableChild(_dependencies, stats);
				}
			}
			Weave.linkableChild(_dependencies, _keySet);
		}
		
		private var _triggerCounter:uint = 0;
		private var _dependencies:ICallbackCollection = Weave.linkableChild(this, CallbackCollection);
		private var _keySet:IKeySet;
		private var _sortCopyFunction:Function = QKeyManager.keySortCopy;
		private var _sortedKeys:Array = [];
		
		public function containsKey(key:IQualifiedKey):Boolean
		{
			return _keySet.containsKey(key);
		}
		
		/**
		 * This is the list of keys from the IKeySet, sorted.
		 */
		public function get keys():Array
		{
			if (_triggerCounter != _dependencies.triggerCounter)
				_validate();
			return _sortedKeys;
		}
		
		private function _validate():void
		{
			_triggerCounter = _dependencies.triggerCounter;
			if (Weave.isBusy(this))
				return;
			
			WeaveAPI.Scheduler.startTask(this, _asyncTask, WeaveAPI.TASK_PRIORITY_NORMAL, _asyncComplete);
		}
		
		private static const EMPTY_ARRAY:Array = []
		
		private function _asyncTask():Number
		{
			// first try sorting an empty array to trigger any column statistics requests
			_sortCopyFunction(EMPTY_ARRAY);
			
			// stop if any async tasks were started
			if (Weave.isBusy(_dependencies))
				return 1;
			
			// sort the keys
			_sortedKeys = _sortCopyFunction(_keySet.keys);
			
			return 1;
		}
		
		private function _asyncComplete():void
		{
			if (Weave.isBusy(_dependencies) || _triggerCounter != _dependencies.triggerCounter)
				return;
			
			Weave.getCallbacks(this).triggerCallbacks();
		}
		
		/**
		 * Generates a function like <code>function(keys:Array):Array</code> that returns a sorted copy of an Array of keys.
		 * Note that the resulting sort function depends on WeaveAPI.StatisticsManager, so the sort function should be called
		 * again when statistics change for any of the columns you provide.
		 * @param columns An Array of IAttributeColumns or Functions mapping IQualifiedKeys to Numbers.
		 * @param sortDirections Sort directions (-1, 0, 1)
		 * @return A function that returns a sorted copy of an Array of keys.
		 */
		public static function generateSortCopyFunction(columns:Array, sortDirections:Array = null):Function
		{
			return function(keys:Array):Array
			{
				var params:Array = [];
				var directions:Array = [];
				var lastDirection:int = 1;
				for (var i:int = 0; i < columns.length; i++)
				{
					var param:Object = columns[i];
					if (Weave.wasDisposed(param))
						continue;
					if (param is IAttributeColumn)
					{
						var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(param as IAttributeColumn);
						param = stats.hack_getNumericData();
					}
					if (!param || param is IKeySet)
						continue;
					if (sortDirections && !sortDirections[i])
						continue;
					lastDirection = (sortDirections ? sortDirections[i] : 1)
					params.push(param);
					directions.push(lastDirection);
				}
				var qkm:QKeyManager = WeaveAPI.QKeyManager as QKeyManager;
				params.push(qkm.map_qkey_keyType, qkm.map_qkey_localName);
				directions.push(lastDirection, lastDirection);
				
				//var t:int = getTimer();
				var result:Array = StandardLib.sortOn(keys, params, directions, false);
				//trace('sorted',keys.length,'keys in',getTimer()-t,'ms',DebugUtils.getCompactStackTrace(new Error()));
				return result;
			};
		}
	}
}