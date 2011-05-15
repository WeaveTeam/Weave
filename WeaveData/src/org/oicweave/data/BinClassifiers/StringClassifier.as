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

package org.oicweave.data.BinClassifiers
{
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.data.IBinClassifier;
	import org.oicweave.core.LinkableString;
	import org.oicweave.utils.VectorUtils;

	/**
	 * StringClassifier
	 * A classifier that accepts a list of String values.
	 * 
	 * @author adufilie
	 */
	public class StringClassifier extends LinkableString implements IBinClassifier
	{
		public function StringClassifier(values:Array = null)
		{
			super();
			addImmediateCallback(this, invalidate);
			setSessionState(values);
		}
		
		private function invalidate():void
		{
			// clear _valueMap because the list of values has changed.
			_valueMap = null;
		}

		/**
		 * This object maps the discrete values contained in this classifier to values of true.
		 */
		private var _valueMap:Object = null;

		/**
		 * @param value A value to test.
		 * @return true If this IBinClassifier contains the given value.
		 */
		public function contains(value:*):Boolean
		{
			// fill _valueMap if necessary
			if (_valueMap == null)
			{
				_valueMap = new Object();
				var values:Array = VectorUtils.flatten(WeaveAPI.CSVParser.parseCSV(_sessionState));
				for each (var str:String in values)
					_valueMap[str] = true;
			}
			
			return _valueMap[value] != undefined;
		}
	}
}
