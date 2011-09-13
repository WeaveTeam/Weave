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

package weave.visualization.plotters.styles
{
	import flash.display.Graphics;
	import flash.utils.Dictionary;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.ui.ILineStyle;
	import weave.compiler.StandardLib;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.utils.ColumnUtils;
	import weave.utils.EquationColumnLib;

	/**
	 * This class defines sessioned parameters for a call to Graphics.lineStyle().
	 * 
	 * @author adufilie
	 */
	public class SolidLineStyle implements ILineStyle
	{
		public function SolidLineStyle()
		{
		}
		
		// This maps an AlwaysDefinedColumn to its preferred value type.
		private const _typesMap:Dictionary = new Dictionary(true);
		// this maps an AlwaysDefinedColumn to the default value for that column.
		// if there is an internal column in the AlwaysDefinedColumn, the default value is not stored
		private const _defaultValues:Dictionary = new Dictionary();
		private var _dirty:Boolean = true; // true when defaultValues are invalid

		/**
		 * @private
		 */
		private function createColumn(valueType:Class, defaultValue:*):AlwaysDefinedColumn
		{
			var column:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn, handleColumnChange);
			_typesMap[column] = valueType;
			column.defaultValue.value = defaultValue;
			return column;
		}

		// this invalidates the default values
		private function handleColumnChange():void
		{
			_dirty = true;
		}
		// this updates the default values
		private function validateDefaultValues():void
		{
			for (var col:* in _typesMap)
			{
				var column:AlwaysDefinedColumn = col as AlwaysDefinedColumn;
				if (column.internalColumn != null)
					delete _defaultValues[column];
				else
					_defaultValues[column] = EquationColumnLib.cast(column.defaultValue.value, _typesMap[column]);
			}
			_dirty = false;
		}

		/**
		 * Used to enable or disable line drawing.
		 */
		public const enabled:AlwaysDefinedColumn = createColumn(Boolean, true);
		
		/**
		 * These properties are used with a basic Graphics.lineStyle() function call.
		 */
		
		public const color:AlwaysDefinedColumn = createColumn(Number, 0x000000);
		public const weight:AlwaysDefinedColumn = createColumn(Number, 1);
		public const alpha:AlwaysDefinedColumn = createColumn(Number, 0.5);
		
		public const pixelHinting:AlwaysDefinedColumn = createColumn(Boolean, false);
		public const scaleMode:AlwaysDefinedColumn = createColumn(String, "normal");
		public const caps:AlwaysDefinedColumn = createColumn(String, null);
		public const joints:AlwaysDefinedColumn = createColumn(String, null);
		public const miterLimit:AlwaysDefinedColumn = createColumn(Number, 3);

		/**
		 * This function sets the line style on a Graphics object using the saved border properties.
		 * @param graphics
		 *     The Graphics object to initialize.
		 */
		public function beginLineStyle(recordKey:IQualifiedKey, target:Graphics):void
		{
			if (_dirty)
				validateDefaultValues();
			
			var _enabled:* = _defaultValues[enabled];
			var _color:* = _defaultValues[color];
			var _weight:* = _defaultValues[weight];
			var _alpha:* = _defaultValues[alpha];
			var _pixelHinting:* = _defaultValues[pixelHinting];
			var _scaleMode:* = _defaultValues[scaleMode];
			var _caps:* = _defaultValues[caps];
			var _joints:* = _defaultValues[joints];
			var _miterLimit:* = _defaultValues[miterLimit];
			
			var lineEnabled:Boolean = _enabled != undefined ? _enabled : StandardLib.asBoolean( enabled.getValueFromKey(recordKey) );
			if (!lineEnabled)
			{
				target.lineStyle(0, 0, 0);
			}
			else
			{
				var lineWeight:Number = _weight != undefined ? _weight : weight.getValueFromKey(recordKey, Number);
				var lineColor:Number = _color != undefined ? _color : color.getValueFromKey(recordKey, Number);
				if (!isNaN(lineColor)) // if color is defined, use basic Graphics.lineStyle() function
				{
					if (lineWeight == 0) // treat lineWeight 0 as no line
					{
						target.lineStyle(0, 0, 0);
					}
					else
					{
						var         lineAlpha:Number = _alpha != undefined ? _alpha               :      alpha.getValueFromKey(recordKey, Number);
						var linePixelHinting:Boolean = _pixelHinting != undefined ? _pixelHinting : ColumnUtils.getBoolean(pixelHinting, recordKey);
						var     lineScaleMode:String = _scaleMode != undefined ? _scaleMode       :  scaleMode.getValueFromKey(recordKey, String) as String;
						var          lineCaps:String = _caps != undefined ? _caps                 :       caps.getValueFromKey(recordKey, String) as String;
						var        lineJoints:String = _joints != undefined ? _joints             :     joints.getValueFromKey(recordKey, String) as String;
						var    lineMiterLimit:Number = _miterLimit != undefined ? _miterLimit     : miterLimit.getValueFromKey(recordKey, Number);

						target.lineStyle(lineWeight, lineColor, lineAlpha, linePixelHinting, lineScaleMode, lineCaps, lineJoints, lineMiterLimit);
						//trace("target.lineStyle(",lineWeight, lineColor, lineAlpha, linePixelHinting, lineScaleMode, lineCaps, lineJoints, lineMiterLimit,");");
					}
				}
				else
				{
					target.lineStyle(0, 0, 0);
				}
			}
		}
	}
}
