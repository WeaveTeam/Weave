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

package weave.data.BinningDefinitions
{
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinClassifier;
	import weave.api.data.IBinningDefinition;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.core.ClassUtils;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableWatcher;
	import weave.data.BinClassifiers.NumberClassifier;
	import weave.data.BinClassifiers.StringClassifier;
	
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
		private const internalResultWatcher:LinkableWatcher = newDisposableChild(this, LinkableWatcher);
		private const internalObjectWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, handleInternalObjectChange);
		private const columnWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, generateBins);
		private const statsWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, generateBins);
		
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
			getCallbackCollection(output).delayCallbacks();
			output.removeAllObjects();
			
			var JSON:Object = ClassUtils.getClassDefinition('JSON');
			if (!JSON)
			{
				reportError("JSON parser unavailable");
				getCallbackCollection(output).resumeCallbacks();
				return false;
			}
			
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
				reportError("Invalid JSON bin specification: " + json, null, e);
				getCallbackCollection(output).resumeCallbacks();
				return false;
			}
			
			getCallbackCollection(output).resumeCallbacks();
			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get asyncResultCallbacks():ICallbackCollection
		{
			return getCallbackCollection(internalResultWatcher);
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
		
		protected var overrideBinsOutput:ILinkableHashMap = registerDisposableChild(this, new LinkableHashMap(IBinClassifier));
		
		// reusable temporary object
		private static const tempNumberClassifier:NumberClassifier = new NumberClassifier();
	}
}
