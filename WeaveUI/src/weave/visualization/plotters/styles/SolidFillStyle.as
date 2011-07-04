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
	
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IFillStyle;
	import weave.compiler.BooleanLib;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;

	/**
	 * SolidFillStyle
	 * 
	 * @author adufilie
	 */
	public class SolidFillStyle implements IFillStyle
	{
		public function SolidFillStyle()
		{
		}

		/**
		 * Used to enable or disable fill patterns.
		 */
		public const enabled:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(true));
		
		/**
		 * These properties are used with a basic Graphics.setFill() function call.
		 */
		public const color:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(NaN));
		public const alpha:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(1.0));
		
		/**
		 * This function sets the fill on a Graphics object using the saved fill properties.
		 * @param recordKey The record key to initialize the fill style for.
		 * @param graphics The Graphics object to initialize.
		 */
		public function beginFillStyle(recordKey:IQualifiedKey, target:Graphics):void
		{
			var fillEnabled:Boolean = BooleanLib.toBoolean( enabled.getValueFromKey(recordKey) );
			var fillColor:Number = color.getValueFromKey(recordKey, Number);
			if (!fillEnabled)
			{
				target.endFill();
			}
			else if (!isNaN(fillColor)) // if color is defined, use basic Graphics.beginFill() function
			{
				var fillAlpha:Number = alpha.getValueFromKey(recordKey, Number);
				target.beginFill(fillColor, fillAlpha);
				//trace("beginFill(",fillColor, fillAlpha,");");
			}
			else
			{
				target.endFill();
			}
		}
	}
}
