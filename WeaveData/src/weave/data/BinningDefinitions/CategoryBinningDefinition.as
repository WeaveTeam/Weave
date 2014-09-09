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
	import flash.utils.getTimer;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newDisposableChild;
	import weave.core.SessionManager;
	import weave.core.StageUtils;
	import weave.data.BinClassifiers.SingleValueClassifier;
	import weave.utils.AsyncSort;

	/**
	 * Creates a separate bin for every string value in a column.
	 * 
	 * @author adufilie
	 */
	public class CategoryBinningDefinition extends AbstractBinningDefinition
	{
		public function CategoryBinningDefinition()
		{
			// no bin names allowed
			overrideBinNames.lock();
			(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, overrideBinNames);
		}
		
		override public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			// get all string values in the a column
			_sortMap = {};
			strArray = new Array(column.keys.length); // alloc max length
			this.column = column;
			i = iout = 0;
			keys = column.keys;
			_iterateAll(-1); // restart from first task
			// high priority because not much can be done without data
			WeaveAPI.StageUtils.startTask(asyncResultCallbacks, _iterateAll, WeaveAPI.TASK_PRIORITY_HIGH, _done);
		}
		
		private var _sortMap:Object; // used by _sortFunc
		private var strArray:Array;
		private var i:int;
		private var iout:int;
		private var str:String;
		private var column:IAttributeColumn;
		private var keys:Array;
		private var _iterateAll:Function = StageUtils.generateCompoundIterativeTask(_iterate1, _iterate2);
		private var asyncSort:AsyncSort = newDisposableChild(this, AsyncSort);
		
		private function _iterate1(stopTime:int):Number
		{
			for (; i < keys.length; i++)
			{
				if (getTimer() > stopTime)
					return i / keys.length;
				
				str = column.getValueFromKey(keys[i], String) as String;
				if (str && !_sortMap.hasOwnProperty(str))
				{
					strArray[int(iout++)] = str;
					_sortMap[str] = column.getValueFromKey(keys[i], Number);
				}
			}
			
			strArray.length = iout; // truncate
			asyncSort.beginSort(strArray, _sortFunc); // sort strings by corresponding numeric values
			i = 0;
			
			return 1;
		}
		
		private function _iterate2(stopTime:int):Number
		{
			if (linkableObjectIsBusy(asyncSort))
				return 0;
			
			for (; i < strArray.length; i++)
			{
				if (getTimer() > stopTime)
					return i / strArray.length;
				
				str = strArray[i] as String;
				
				var svc:SingleValueClassifier = output.requestObject(str, SingleValueClassifier, false);
				svc.value = strArray[i];
			}
			
			return 1;
		}
		
		private function _done():void
		{
			asyncResultCallbacks.triggerCallbacks();
		}
		
		/**
		 * This function sorts string values by their corresponding numeric values stored in _sortMap.
		 */
		private function _sortFunc(str1:String, str2:String):int
		{
			return ObjectUtil.numericCompare(_sortMap[str1], _sortMap[str2])
				|| ObjectUtil.stringCompare(str1, str2);
		}
	}
}
