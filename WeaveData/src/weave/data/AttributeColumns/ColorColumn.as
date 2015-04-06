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

package weave.data.AttributeColumns
{
	import flash.utils.Dictionary;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
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
			_internalColumnStats = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(internalDynamicColumn));
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.DATA_TYPE)
				return DataType.STRING;
			
			return super.getMetadata(propertyName);
		}
		
		// color values depend on the min,max stats of the internal column
		private var _internalColumnStats:IColumnStatistics;
		
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
		private var _recordColorsTriggerCounter:uint = 0;
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_recordColorsTriggerCounter != recordColors.triggerCounter)
			{
				_recordColorsTriggerCounter = recordColors.triggerCounter;
				handleRecordColors();
			}
			
			var color:Number;

			var recordColor:* = _recordColorsMap[key];
			if (recordColor !== undefined)
			{
				color = recordColor;
			}
			else
			{
				var dataMin:Number = _internalColumnStats.getMin();
				var dataMax:Number = _internalColumnStats.getMax();
				var value:Number = internalDynamicColumn.getValueFromKey(key, Number);
				var norm:Number;
				if (dataMin == dataMax)
					norm = isFinite(value) ? 0 : NaN;
				else
					norm = (value - dataMin) / (dataMax - dataMin);
				color = ramp.getColorFromNorm(norm);
			}
			
			if (dataType == Number)
				return color;
			
			// return a 6-digit hex value for a String version of the color
			if (isFinite(color))
				return '#' + StandardLib.numberToBase(color, 16, 6);
			
			return '';
		}

//		public function deriveStringFromNumber(value:Number):String
//		{
//			if (isNaN(value))
//				return "NaN";
//			return '#' + StringLib.toBase(value, 16, 6);
//		}
	}
}
