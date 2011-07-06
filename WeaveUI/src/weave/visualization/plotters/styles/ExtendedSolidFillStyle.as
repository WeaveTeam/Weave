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
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.SpreadMethod;
	import flash.geom.Matrix;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.compiler.BooleanLib;
	import weave.core.LinkableBoolean;

	/**
	 * Draws a fill pattern when no color is specified.
	 * 
	 * @author abaumann
	 */
	public class ExtendedSolidFillStyle extends SolidFillStyle
	{
		public function ExtendedSolidFillStyle()
		{
			super();
			_matrix = new Matrix();
 			_matrix.createGradientBox(10, 10, 45, 0, 0);
		}
		
		public const enableMissingDataFillPattern:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		/**
		 * This function sets the fill on a Graphics object using the saved fill properties.
		 * @param recordKey The record key to initialize the fill style for.
		 * @param graphics The Graphics object to initialize.
		 */
		private var _matrix:Matrix = null;
		override public function beginFillStyle(recordKey:IQualifiedKey, target:Graphics):void
		{
			if (enableMissingDataFillPattern.value)
			{
				var fillEnabled:Boolean = BooleanLib.toBoolean( enabled.getValueFromKey(recordKey) );
				var fillColor:Number = color.getValueFromKey(recordKey, Number);
				if (fillEnabled && isNaN(fillColor))
				{
					target.beginGradientFill(
							GradientType.LINEAR,
							[0x808080, 0xFFFFFF],
							[0.5, 0.5],
							[0, 255],
							_matrix,
							SpreadMethod.REFLECT//.REPEAT
						);
					return;
				}
			}
			super.beginFillStyle(recordKey, target);
		}
	}
}
