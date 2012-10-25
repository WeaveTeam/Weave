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
	import weave.compiler.StandardLib;

	/**
	 * Allows the line to be drawn using the missing style pattern.
	 *  
	 * @author abaumann
	 */
	public class ExtendedLineStyle extends SolidLineStyle
	{
		public function ExtendedLineStyle()
		{
			super();
			color.defaultValue.value = NaN;
		}

		private var _matrix:Matrix = null;
		override public function beginLineStyle(recordKey:IQualifiedKey, target:Graphics):void
		{
			var lineEnabled:Boolean = StandardLib.asBoolean( enabled.getValueFromKey(recordKey) );
			var lineWeight:Number = weight.getValueFromKey(recordKey, Number);
			var lineColor:Number = color.getValueFromKey(recordKey, Number);

			
			if (lineEnabled && lineWeight > 0 && isNaN(lineColor))
			{
				if (!_matrix)
				{
					_matrix = new Matrix();
	 				_matrix.createGradientBox(5, 5, 45, 0, 0);
				}

				target.lineStyle(lineWeight, 0, 0); // this is necessary to set the correct line thickness
				target.lineGradientStyle(GradientType.LINEAR, 
							        [0xFFFFFF, 0x000000],
							        [0.5, 0.5],
							        [20, 255],
							        _matrix,
							        SpreadMethod.REFLECT);
			}
			else
			{
				super.beginLineStyle(recordKey, target);
			}
		}
	}
}
