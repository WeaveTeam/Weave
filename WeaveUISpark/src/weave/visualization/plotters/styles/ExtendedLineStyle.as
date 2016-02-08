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
	[ExcludeClass] public class ExtendedLineStyle extends SolidLineStyle
	{
		public function ExtendedLineStyle()
		{
			super();
			color.defaultValue.value = NaN;
		}

		private var _matrix:Matrix = null;
		override public function beginLineStyle(recordKey:IQualifiedKey, target:Graphics):void
		{
			var lineWeight:Number = weight.getValueFromKey(recordKey, Number);
			var lineColor:Number = color.getValueFromKey(recordKey, Number);
			
			if (enable.getSessionState() && lineWeight > 0 && isNaN(lineColor))
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
