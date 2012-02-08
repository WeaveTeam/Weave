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
	import flash.utils.Dictionary;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.detectLinkableObjectChange;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
	import weave.data.QKeyManager;
	import weave.primitives.ColorRamp;
	
	/**
	 * ColorColumn
	 * 
	 * @author adufilie
	 */
	public class ColorColumn extends ExtendedDynamicColumn
	{
		public function ColorColumn()
		{
		}
		
		public const ramp:ColorRamp = newLinkableChild(this, ColorRamp);
		
		/**
		 * This is a CSV containing specific colors associated with record keys.
		 * The format for each row in the CSV is:  keyType,localName,color
		 */
		public const recordColors:LinkableString = newLinkableChild(this, LinkableString);
		private var _recordColorsMap:Dictionary;
		private function handleRecordColors():void
		{
			var rows:Array = WeaveAPI.CSVParser.parseCSV(recordColors.value);
			_recordColorsMap = new Dictionary();
			for (var iRow:int = 0; iRow < rows.length; iRow++)
			{
				var row:Array = rows[iRow] as Array;
				if (row.length != 3)
					continue;
				try
				{
					var key:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(row[0], row[1]);
					var color:Number = StandardLib.asNumber(row[2]);
					_recordColorsMap[key] = color;
				}
				catch (e:Error)
				{
					reportError(e);
				}
			}
		}
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (detectLinkableObjectChange(handleRecordColors, recordColors))
				handleRecordColors();
			
			var color:Number;

			var recordColor:* = _recordColorsMap[key];
			if (recordColor !== undefined)
			{
				color = recordColor;
			}
			else
			{
				var column:IAttributeColumn = internalDynamicColumn.internalColumn;
				var dataMin:Number = WeaveAPI.StatisticsCache.getMin(column);
				var dataMax:Number = WeaveAPI.StatisticsCache.getMax(column);
				var value:Number = column ? column.getValueFromKey(key, Number) : NaN;
				if (isNaN(value) || value < dataMin || value > dataMax)
					return NaN;
				
				var norm:Number = (value - dataMin) / (dataMax - dataMin);
				color = ramp.getColorFromNorm(norm);
			}
			
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
