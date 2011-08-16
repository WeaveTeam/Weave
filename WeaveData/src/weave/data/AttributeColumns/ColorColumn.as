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

package weave.data.AttributeColumns
{
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.compiler.StandardLib;
	import weave.primitives.ColorRamp;
	
	/**
	 * ColorColumn
	 * 
	 * @author adufilie
	 */
	public class ColorColumn extends ExtendedDynamicColumn //implements IPrimitiveColumn
	{
		public function ColorColumn()
		{
		}
		
		public const ramp:ColorRamp = newLinkableChild(this, ColorRamp);
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var column:IAttributeColumn = internalDynamicColumn.internalColumn;
			var dataMin:Number = WeaveAPI.StatisticsCache.getMin(column);
			var dataMax:Number = WeaveAPI.StatisticsCache.getMax(column);

			var value:Number = column ? column.getValueFromKey(key, Number) : NaN;
			if (isNaN(value) || value < dataMin || value > dataMax)
				return NaN;
				
			var norm:Number = (value - dataMin) / (dataMax - dataMin);
			
			var color:Number = ramp.getColorFromNorm(norm);
			// return a 6-digit hex value for a String version of the color
			if (dataType == String && !isNaN(color))
				return '0x' + StandardLib.numberToBase(color, 16, 6);
			return color;
		}

//		public function deriveStringFromNumber(value:Number):String
//		{
//			if (isNaN(value))
//				return "NaN";
//			return '0x' + StringLib.toBase(value, 16, 6);
//		}
	}
}
