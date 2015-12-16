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
	import weavejs.api.data.IBinClassifier;
	import weavejs.core.LinkableVariable;
	import weavejs.util.StandardLib;

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
				for each (var str:String in _sessionStateInternal)
					_valueMap[str] = true;
			}
			
			return _valueMap[value] != undefined;
		}
	}
}
