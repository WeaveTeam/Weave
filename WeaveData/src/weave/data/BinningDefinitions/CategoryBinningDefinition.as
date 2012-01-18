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
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinningDefinition;
	import weave.api.data.IQualifiedKey;
	import weave.data.BinClassifiers.SingleValueClassifier;
	import weave.utils.ColumnUtils;

	/**
	 * Creates a separate bin for every string value in a column.
	 * 
	 * @author adufilie
	 */
	public class CategoryBinningDefinition extends AbstractBinningDefinition
	{
		public function CategoryBinningDefinition()
		{
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
		override public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
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
				if (!_sortMap.hasOwnProperty(str))
				{
					strArray[int(i++)] = str;
					_sortMap[str] = column.getValueFromKey(key, Number);
				}
			}
			strArray.length = i; // truncate
			strArray.sort(_sortFunc); // sort strings by corresponding numeric values
			var n:int = strArray.length;
			for (i = 0; i < n; i++)
			{
				//first get name from overrideBinNames
				str = getNameFromOverrideString(i);
				//if it is empty string set it from generateBinLabel
				if(!str)
					str = strArray[i] as String;
				var svc:SingleValueClassifier = output.requestObject(str, SingleValueClassifier, false);
				svc.value = strArray[i];
			}
		}
	}
}
