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
	import flash.utils.getTimer;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.compiler.StandardLib;
	
	public class ColumnDataTask
	{
		public function ColumnDataTask(parentColumn:IAttributeColumn, dataFilter:Function = null, callback:Function = null)
		{
			if (callback == null)
				callback = parentColumn.triggerCallbacks;
			
			this.parentColumn = parentColumn;
			this.dataFilter = dataFilter;
			this.callback = callback;
		}
		
		/**
		 * Asynchronous output.
		 * recordKey:IQualifiedKey -&gt; Array&lt;Number&gt;
		 */
		public var uniqueKeys:Array = [];
		
		/**
		 * Asynchronous output.
		 * (dataType:Class, recordKey:IQualifiedKey) -&gt; value
		 */
		public var arrayData:Dictionary = new Dictionary();
		
		/**
		 * @param inputKeys A Vector (or Array) of IQualifiedKey objects.
		 * @param inputData A Vector (or Array) of data values corresponding to the inputKeys.
		 * @param relevantContext
		 * @param callback
		 */
		public function begin(inputKeys:*, inputData:*):void
		{
			if (inputKeys.length != inputData.length)
				throw new Error(StandardLib.substitute("Arrays are of different length ({0} != {1})", inputKeys.length, inputData.length));
			
			this.dataFilter = dataFilter;
			keys = inputKeys;
			data = inputData;
			i = 0;
			n = keys.length;
			uniqueKeys = [];
			arrayData = new Dictionary();
			
			// high priority because not much can be done without data
			WeaveAPI.StageUtils.startTask(parentColumn, iterate, WeaveAPI.TASK_PRIORITY_HIGH, callback, lang("Processing {0} records", n));
		}
		
		private var parentColumn:IAttributeColumn;
		private var dataFilter:Function;
		private var callback:Function;
		private var keys:*;
		private var data:*;
		private var i:int;
		private var n:int;
		
		private function iterate(stopTime:int):Number
		{
			for (; i < n; i++)
			{
				if (getTimer() > stopTime)
					return i / n;
				
				var value:* = data[i];
				if (dataFilter != null && !dataFilter(value))
					continue;
				
				var key:IQualifiedKey = keys[i];
				var array:Array = arrayData[key] as Array;
				if (!array)
				{
					uniqueKeys.push(key);
					arrayData[key] = array = [value];
				}
				else
				{
					array.push(value);
				}
			}
			return 1;
		}
	}
}
