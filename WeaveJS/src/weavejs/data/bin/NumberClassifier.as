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
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IBinClassifier;
	import weavejs.core.LinkableBoolean;
	import weavejs.core.LinkableNumber;
	import weavejs.data.ColumnUtils;
	import weavejs.util.StandardLib;
	
	/**
	 * A classifier that uses min,max values for containment tests.
	 * 
	 * @author adufilie
	 */
	public class NumberClassifier implements IBinClassifier
	{
		public function NumberClassifier(min:* = NaN, max:* = NaN, minInclusive:Boolean = true, maxInclusive:Boolean = true)
		{
			super();
			_callbacks = Weave.getCallbacks(this);
			this.min.value = min;
			this.max.value = max;
			this.minInclusive.value = minInclusive;
			this.maxInclusive.value = maxInclusive;
		}

		/**
		 * These values define the bounds of the continuous range contained in this classifier.
		 */
		public var min:LinkableNumber = Weave.linkableChild(this, LinkableNumber);
		public var max:LinkableNumber = Weave.linkableChild(this, LinkableNumber);

		/**
		 * This value is the result of contains(value) when value == min.
		 */
		public var minInclusive:LinkableBoolean = Weave.linkableChild(this, LinkableBoolean);
		/**
		 * This value is the result of contains(value) when value == max.
		 */
		public var maxInclusive:LinkableBoolean = Weave.linkableChild(this, LinkableBoolean);

		// private variables for holding session state, used for speed
		private var _callbacks:ICallbackCollection;
		private var _triggerCount:uint = 0;
		private var _min:Number, _max:Number;
		private var _minInclusive:Boolean, _maxInclusive:Boolean;

		/**
		 * contains
		 * @param value A value to test.
		 * @return true If this IBinClassifier contains the given value.
		 */
		public function contains(value:*):Boolean
		{
			// validate private variables before trying to use them
			if (_triggerCount != _callbacks.triggerCounter)
			{
				_min = min.value;
				_max = max.value;
				_minInclusive = minInclusive.value;
				_maxInclusive = maxInclusive.value;
				_triggerCount = _callbacks.triggerCounter;
			}
			// use private variables for speed
			if (_minInclusive ? value >= _min : value > _min)
				if (_maxInclusive ? value <= _max : value < _max)
					return true;
			return false;
		}
		
		/**
		 * @param toStringColumn The primitive column to use that provides a number-to-string conversion function.
		 * @return A generated label for this NumberClassifier.
		 */
		public function generateBinLabel(toStringColumn:IAttributeColumn = null):String
		{
			var minStr:String = null;
			var maxStr:String = null;
			
			// get labels from column
			minStr = ColumnUtils.deriveStringFromNumber(toStringColumn, min.value) || '';
			maxStr = ColumnUtils.deriveStringFromNumber(toStringColumn, max.value) || '';
			
			// if the column produced no labels, use default number formatting
			if (!minStr && !maxStr)
			{
				minStr = StandardLib.formatNumber(min.value);
				maxStr = StandardLib.formatNumber(max.value);
			}
			
			// if both labels are the same, return the label
			if (minStr && maxStr && minStr == maxStr)
				return minStr;
			
			// if the column dataType is string, put quotes around the labels
			if (toStringColumn && toStringColumn.getMetadata(ColumnMetadata.DATA_TYPE) == DataType.STRING)
			{
				minStr = Weave.lang('"{0}"', minStr);
				maxStr = Weave.lang('"{0}"', maxStr);
			}
			else
			{
				if (!minInclusive.value)
					minStr = Weave.lang("> {0}", minStr);
				if (!maxInclusive.value)
					maxStr = Weave.lang("< {0}", maxStr);
			}

			if (minStr == '')
				minStr = Weave.lang('Undefined');
			if (maxStr == '')
				maxStr = Weave.lang('Undefined');
			
			return Weave.lang("{0} to {1}", minStr, maxStr);
		}
		
		public function toString():String
		{
			return (minInclusive.value ? '[' : '(')
				+ min.value + ', ' + max.value
				+ (maxInclusive.value ? ']' : ')');
		}
	}
}
