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

package weave.utils;

public class Numbers
{
	public static double roundSignificant(double value, int significantDigits)
	{
		// it doesn't make sense to round infinity or NaN
		if (Double.isInfinite(value) || Double.isNaN(value))
			return value;
		
		double sign = (value < 0) ? -1 : 1;
		double absValue = Math.abs(value);
		double pow10;
		
		// if absValue is less than 1, all digits after the decimal point are significant
		if (absValue < 1)
		{
			pow10 = Math.pow(10, significantDigits);
			//trace("absValue<1: Math.round(",absValue,"*",pow10,")",Math.round(absValue * pow10));
			return sign * Math.round(absValue * pow10) / pow10;
		}
		
		double log10 = Math.ceil(Math.log10(absValue));
		
		// Both these calculations are equivalent mathematically, but if we use
		// the wrong one we get bad rounding results like "123.456000000001".
		if (log10 < significantDigits)
		{
			// find the power of 10 that you need to MULTIPLY absValue by
			// so Math.round() will round off the digits we don't want
			pow10 = Math.pow(10, significantDigits - log10);
			return sign * Math.round(absValue * pow10) / pow10;
		}
		else
		{
			// find the power of 10 that you need to DIVIDE absValue by
			// so Math.round() will round off the digits we don't want
			pow10 = Math.pow(10, log10 - significantDigits);
			return sign * Math.round(absValue / pow10) * pow10;
		}
	}
}
