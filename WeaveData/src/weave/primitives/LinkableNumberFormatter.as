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

package weave.primitives
{
	import mx.formatters.NumberFormatter;
	
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;

	/**
	 * This is a sessioned NumberFormatter object.
	 * All the properties of an internal NumberFormatter object are accessible through the public sessioned properties of this class.
	 * 
	 * @author adufilie
	 */
	public class LinkableNumberFormatter implements ILinkableObject
	{
		public function LinkableNumberFormatter()
		{
			decimalSeparatorFrom.value = _nf.decimalSeparatorFrom;
			decimalSeparatorTo.value = _nf.decimalSeparatorTo;
			precision.value = Number(_nf.precision);
			rounding.value = _nf.rounding;
			thousandsSeparatorFrom.value = _nf.thousandsSeparatorFrom;
			thousandsSeparatorTo.value = _nf.thousandsSeparatorTo;
			useNegativeSign.value = _nf.useNegativeSign;
			useThousandsSeparator.value = _nf.useThousandsSeparator;
		}
		
		/**
		 * This function calls format() on the internal NumberFormatter object.
		 * @param value The value to format.
		 * @return The value, formatted using the internal NumberFormatter.
		 */
		public function format(value:Object):String
		{
			if (_invalid)
				validate();
			return _nf.format(value);
		}

		public const decimalSeparatorFrom:LinkableString = newLinkableChild(this, LinkableString, invalidate);
		public const decimalSeparatorTo:LinkableString = newLinkableChild(this, LinkableString, invalidate);
		public const precision:LinkableNumber = newLinkableChild(this, LinkableNumber, invalidate);
		public const rounding:LinkableString = newLinkableChild(this, LinkableString, invalidate);
		public const thousandsSeparatorFrom:LinkableString = newLinkableChild(this, LinkableString, invalidate);
		public const thousandsSeparatorTo:LinkableString = newLinkableChild(this, LinkableString, invalidate);
		public const useNegativeSign:LinkableBoolean = newLinkableChild(this, LinkableBoolean, invalidate);
		public const useThousandsSeparator:LinkableBoolean = newLinkableChild(this, LinkableBoolean, invalidate);
		
		/**
		 * This is the internal NumberFormatter object.
		 */
		private const _nf:NumberFormatter = new NumberFormatter();
		/**
		 * This is a flag that is set by invalidate() to remember that the _nf properties need to be validated.
		 */
		private var _invalid:Boolean = false;
		/**
		 * This function invalidates the properties of _nf.
		 */
		private function invalidate():void
		{
			_invalid = true;
		}
		/**
		 * This function will validate the properties of _nf.
		 */
		private function validate():void
		{
			// validate now
			copyTo(_nf);
			_invalid = false;
		}
		
		/**
		 * @param numberFormatter A NumberFormatter to copy the settings to.
		 */
		public function copyTo(numberFormatter:NumberFormatter):void
		{
			numberFormatter.decimalSeparatorFrom = decimalSeparatorFrom.value;
			numberFormatter.decimalSeparatorTo = decimalSeparatorTo.value;
			numberFormatter.precision = precision.value;
			numberFormatter.rounding = rounding.value;
			numberFormatter.thousandsSeparatorFrom = thousandsSeparatorFrom.value;
			numberFormatter.thousandsSeparatorTo = thousandsSeparatorTo.value;
			numberFormatter.useNegativeSign = useNegativeSign.value;
			numberFormatter.useThousandsSeparator = useThousandsSeparator.value;
		}
	}
}
