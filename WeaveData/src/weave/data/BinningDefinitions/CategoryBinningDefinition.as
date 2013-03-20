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
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
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
			overrideBinNames.lock(); // no bin names allowed
		}
		
		/**
		 * This function sorts string values by their corresponding numeric values stored in _sortMap.
		 */
		private function _sortFunc(str1:String, str2:String):int
		{
			return ObjectUtil.numericCompare(_sortMap[str1], _sortMap[str2])
				|| ObjectUtil.stringCompare(str1, str2);
		}
		
		private var _sortMap:Object; // used by _sortFunc
		
		/**
		 * derive an explicit definition.
		 */
		override public function generateBinClassifiersForColumn(column:IAttributeColumn):void
		{
			// clear any existing bin classifiers
			output.removeAllObjects();
			
			// get all string values in the a column
			_sortMap = {};
			var strArray:Array = new Array(column.keys.length); // alloc max length
			var i:int = 0;
			var str:String;
			for each (var key:IQualifiedKey in column.keys)
			{
				str = column.getValueFromKey(key, String) as String;
				if (str && !_sortMap.hasOwnProperty(str))
				{
					strArray[int(i++)] = str;
					_sortMap[str] = column.getValueFromKey(key, Number);
				}
			}
			strArray.length = i; // truncate
			AsyncSort.sortImmediately(strArray, _sortFunc); // sort strings by corresponding numeric values
			var n:int = strArray.length;
			for (i = 0; i < n; i++)
			{
				//first get name from overrideBinNames
				str = strArray[i] as String;
				
				//TODO: look up replacement name once we store original + modified names together rather than a simple Array of replacement names.
				
				var svc:SingleValueClassifier = output.requestObject(str, SingleValueClassifier, false);
				svc.value = strArray[i];
			}
			
			// trigger callbacks now because we're done updating the output
			asyncResultCallbacks.triggerCallbacks();
		}
	}
}
