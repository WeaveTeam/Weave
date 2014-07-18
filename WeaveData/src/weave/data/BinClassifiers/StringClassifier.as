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

package weave.data.BinClassifiers
{
	import weave.api.WeaveAPI;
	import weave.api.data.IBinClassifier;
	import weave.compiler.StandardLib;
	import weave.core.LinkableVariable;

	/**
	 * A classifier that accepts a list of String values.
	 * 
	 * @author adufilie
	 */
	public class StringClassifier extends LinkableVariable implements IBinClassifier
	{
		public function StringClassifier()
		{
			super(Array, isStringArray);
		}
		
		override public function setSessionState(value:Object):void
		{
			// backwards compatibility
			if (value is String)
				value = WeaveAPI.CSVParser.parseCSVRow(value as String);
			super.setSessionState(value);
		}
		
		private function isStringArray(array:Array):Boolean
		{
			return StandardLib.getArrayType(array) == String;
		}
		
		/**
		 * This object maps the discrete values contained in this classifier to values of true.
		 */
		private var _valueMap:Object = null;
		
		private var _triggerCount:int = 0;

		/**
		 * @param value A value to test.
		 * @return true If this IBinClassifier contains the given value.
		 */
		public function contains(value:*):Boolean
		{
			if (_triggerCount != triggerCounter)
			{
				_triggerCount = triggerCounter;
				_valueMap = {};
				for each (var str:String in _sessionState)
					_valueMap[str] = true;
			}
			
			return _valueMap[value] != undefined;
		}
	}
}
