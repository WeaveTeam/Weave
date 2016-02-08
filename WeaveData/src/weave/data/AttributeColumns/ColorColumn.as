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
	import weave.core.LinkableBoolean;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
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
			super();
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
		public const rampCenterAtZero:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), cacheState);
		
		private var _rampCenterAtZero:Boolean;
		private function cacheState():void
		{
			_rampCenterAtZero = rampCenterAtZero.value;
		}
		
		public function getDataMin():Number
		{
			if (_rampCenterAtZero)
			{
				var dataMin:Number = _internalColumnStats.getMin();
				var dataMax:Number = _internalColumnStats.getMax();
				return -Math.max(Math.abs(dataMin), Math.abs(dataMax));
			}
			return _internalColumnStats.getMin();
		}
		public function getDataMax():Number
		{
			if (_rampCenterAtZero)
			{
				var dataMin:Number = _internalColumnStats.getMin();
				var dataMax:Number = _internalColumnStats.getMax();
				return Math.max(Math.abs(dataMin), Math.abs(dataMax));
			}
			return _internalColumnStats.getMax();
		}
		public function getColorFromDataValue(value:Number):Number
		{
			var dataMin:Number = _internalColumnStats.getMin();
			var dataMax:Number = _internalColumnStats.getMax();
			var norm:Number;
			if (dataMin == dataMax)
			{
				norm = isFinite(value) ? 0.5 : NaN;
			}
			else if (_rampCenterAtZero)
			{
				var absMax:Number = Math.max(Math.abs(dataMin), Math.abs(dataMax));
				norm = (value + absMax) / (2 * absMax);
			}
			else
			{
				norm = (value - dataMin) / (dataMax - dataMin);
			}
			return ramp.getColorFromNorm(norm);
		}
		
		/**
		 * This is a CSV containing specific colors associated with record keys.
		 * The format for each row in the CSV is:  keyType,localName,color
		 */
		public const recordColors:LinkableVariable = registerLinkableChild(this, new LinkableVariable(null, verifyRecordColors));
		private function verifyRecordColors(value:Object):Boolean
		{
			if (value is String)
			{
				value = WeaveAPI.CSVParser.parseCSV(value as String);
				recordColors.setSessionState(value);
				return false;
			}
			if (value === null)
				return true;
			
			return value is Array && StandardLib.arrayIsType(value as Array, Array);
		}
		private var _recordColorsMap:Dictionary;
		private function handleRecordColors():void
		{
			var rows:Array = recordColors.getSessionState() as Array;
			_recordColorsMap = new Dictionary();
			for each (var row:Array in rows)
			{
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
				var value:Number = internalDynamicColumn.getValueFromKey(key, Number);
				color = getColorFromDataValue(value);
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
