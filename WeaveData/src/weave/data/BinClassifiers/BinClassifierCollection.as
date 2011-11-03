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
	import weave.api.data.IBinClassifier;
	import weave.core.LinkableHashMap;
	import weave.core.weave_internal;
	
	/**
	 * This object contains an ordered, named list of IBinClassifier objects.
	 * It also represents a compound IBinClassifier object which is the union of all the internal IBinClassifiers.
	 * 
	 * @author adufilie
	 */
	public class BinClassifierCollection extends LinkableHashMap implements IBinClassifier
	{
		public function BinClassifierCollection()
		{
			super(IBinClassifier)
			addImmediateCallback(this, invalidateBins);
		}
		
		/**
		 * This is a private copy of the last getNames() result.
		 */
		private var _names:Array = [];
		/**
		 * This is a private copy of the last getObjects() result.
		 */
		private var _bins:Array = [];

		/**
		 * This function will update the local arrays if necessary.
		 */
		private function validateLocalArrays():void
		{
			if (_names == null || this.callbacksWereTriggered)
			{
				_names = getNames();
				_bins = getObjects();
			}
		}

		/**
		 * This function gets called when the LinkableHashMap changes.
		 * Local Arrays will be invalidated.
		 */
		private function invalidateBins():void
		{
			// invalidate local copies
			_names = null;
			_bins = null;
		}

		/**
		 * @param value A data value to test.
		 * @return The name of the IBinClassifier containing this value, or null if no bin contains the value.
		 */
		public function getBinNameFromDataValue(value:*):String
		{
			validateLocalArrays();
			for (var i:int = 0; i < _bins.length; i++)
				if ((_bins[i] as IBinClassifier).contains(value))
					return _names[i];
			return null;
		}

		/**
		 * @param value A data value to test.
		 * @return The IBinClassifier containing this value, or null if no bin contains the value.
		 */
		public function getBinClassifierFromDataValue(value:*):IBinClassifier
		{
			validateLocalArrays();
			for (var i:int = 0; i < _bins.length; i++)
				if ((_bins[i] as IBinClassifier).contains(value))
					return _bins[i];
			return null;
		}

		/**
		 * @param value A data value to test.
		 * @return Index of bin containing this value, or NaN if no bin contains the value. 
		 */
		public function getBinIndexFromDataValue(value:*):Number
		{
			validateLocalArrays();
			for (var i:int = 0; i < _bins.length; i++)
				if ((_bins[i] as IBinClassifier).contains(value))
					return i;
			return NaN;
		}
		
		/**
		 * A BinClassifierCollection is the union of a list of IBinClassifier objects.
		 * @param value A data value to test.
		 * @return A value of true if any of the internal IBinClassifier objects return true from their contains() functions.
		 */
		public function contains(value:*):Boolean
		{
			validateLocalArrays();
			for (var i:int = 0; i < _bins.length; i++)
				if ((_bins[i] as IBinClassifier).contains(value))
					return true;
			return false;
		}
	}
}
