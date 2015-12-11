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

package weavejs.data.bin
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IBinClassifier;
	import weavejs.api.data.IBinningDefinition;
	import weavejs.core.LinkableDynamicObject;
	import weavejs.core.LinkableHashMap;
	import weavejs.core.LinkableWatcher;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	
	/**
	 * This provides a wrapper for a dynamically created IBinningDefinition.
	 * When <code>generateBinClassifiersForColumn(column)</code> is called, the column
	 * will be monitored for changes and results will be computed automatically.
	 */
	public class DynamicBinningDefinition extends LinkableDynamicObject implements IBinningDefinition
	{
		/**
		 * @param lockFirstColumn If set to true, the first column passed to <code>generateBinClassifiersForColumn()</code> will be the only column accepted.
		 */
		public function DynamicBinningDefinition(lockFirstColumn:Boolean = false)
		{
			super(IBinningDefinition);
			addImmediateCallback(null, watchInternalObject);
			_columnLocked = lockFirstColumn;
		}
		
		private var _columnLocked:Boolean = false;
		private var internalResultWatcher:LinkableWatcher = Weave.disposableChild(this, LinkableWatcher);
		private var internalObjectWatcher:LinkableWatcher = Weave.linkableChild(this, LinkableWatcher, handleInternalObjectChange);
		private var columnWatcher:LinkableWatcher = Weave.linkableChild(this, LinkableWatcher, generateBins);
		private var statsWatcher:LinkableWatcher = Weave.linkableChild(this, LinkableWatcher, generateBins);
		
		private function watchInternalObject():void
		{
			internalObjectWatcher.target = internalObject;
		}
		
		private function handleInternalObjectChange():void
		{
			if (internalObject)
				internalResultWatcher.target = (internalObject as IBinningDefinition).asyncResultCallbacks
			generateBins();
		}
		
		private var _updatingTargets:Boolean = false;
		private function generateBins():void
		{
			// prevent recursion if this function is called as a result of updating targets
			if (_updatingTargets)
				return;
			_updatingTargets = true;
			
			var column:IAttributeColumn = columnWatcher.target as IAttributeColumn;
			statsWatcher.target = column ? WeaveAPI.StatisticsCache.getColumnStatistics(column) : null;
			
			_updatingTargets = false; // done preventing recursion
			
			var overrideBins:String = column ? column.getMetadata(ColumnMetadata.OVERRIDE_BINS) : null;
			if (overrideBins && getBinsFromJson(overrideBins, overrideBinsOutput, column))
				asyncResultCallbacks.triggerCallbacks();
			else
				overrideBinsOutput.removeAllObjects();
			
			if (internalObject && column)
				(internalObject as IBinningDefinition).generateBinClassifiersForColumn(column);
			else
				asyncResultCallbacks.triggerCallbacks(); // bins are empty
		}
		
		/**
		 * @param json Any one of the following formats:
		 *     [1,2,3]<br>
		 *     [[0,5],[5,10]]<br>
		 *     [{"min": 0, "max": 33, "label": "low"}, {"min": 34, "max": 66, "label": "midrange"}, {"min": 67, "max": 100, "label": "high"}]
		 * @return true on success
		 */
		public static function getBinsFromJson(json:String, output:ILinkableHashMap, toStringColumn:IAttributeColumn = null):Boolean
		{
			if (!tempNumberClassifier)
				tempNumberClassifier = new NumberClassifier();
			
			Weave.getCallbacks(output).delayCallbacks();
			output.removeAllObjects();
			
			var array:Array;
			try
			{
				array = JSON.parse(json) as Array;
				
				for each (var item:Object in array)
				{
					var label:String;
					if (item is String || StandardLib.getArrayType(item as Array) == String)
					{
						label = ((item as Array || [item]) as Array).join(', ');
						var sc:StringClassifier = output.requestObject(label, StringClassifier, false);
						sc.setSessionState(item as Array || [item]);
					}
					else
					{
						tempNumberClassifier.min.value = -Infinity;
						tempNumberClassifier.max.value = Infinity;
						tempNumberClassifier.minInclusive.value = true;
						tempNumberClassifier.maxInclusive.value = true;
						
						if (item is Array)
						{
							tempNumberClassifier.min.value = item[0];
							tempNumberClassifier.max.value = item[1];
						}
						else if (item is Number)
						{
							tempNumberClassifier.min.value = item as Number;
							tempNumberClassifier.max.value = item as Number;
						}
						else
						{
							WeaveAPI.SessionManager.setSessionState(tempNumberClassifier, item);
						}
						
						if (item && typeof item == 'object' && item['label'])
							label = item['label'];
						else
							label = tempNumberClassifier.generateBinLabel(toStringColumn);
						output.requestObjectCopy(label, tempNumberClassifier);
					}
				}
			}
			catch (e:Error)
			{
				JS.error("Invalid JSON bin specification: " + json, null, e);
				Weave.getCallbacks(output).resumeCallbacks();
				return false;
			}
			
			Weave.getCallbacks(output).resumeCallbacks();
			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get asyncResultCallbacks():ICallbackCollection
		{
			return Weave.getCallbacks(internalResultWatcher);
		}

		/**
		 * @inheritDoc
		 */
		public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			if (_columnLocked && columnWatcher.target)
				throw new Error("generateBinClassifiersForColumn(): Column was locked upon creation of this DynamicBinningDefinition.");
			columnWatcher.target = column;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getBinClassifiers():Array
		{
			var override:Array = overrideBinsOutput.getObjects();
			if (override.length)
				return override;
			if (internalObject && columnWatcher.target)
				return (internalObject as IBinningDefinition).getBinClassifiers();
			return [];
		}
		
		/**
		 * @inheritDoc
		 */
		public function getBinNames():Array
		{
			var override:Array = overrideBinsOutput.getNames();
			if (override.length)
				return override;
			if (internalObject && columnWatcher.target)
				return (internalObject as IBinningDefinition).getBinNames();
			return [];
		}
		
		public function get binsOverridden():Boolean
		{
			return overrideBinsOutput.getNames().length > 0;
		}
		
		protected var overrideBinsOutput:ILinkableHashMap = Weave.disposableChild(this, new LinkableHashMap(IBinClassifier));
		
		// reusable temporary object
		private static var tempNumberClassifier:NumberClassifier;
	}
}
