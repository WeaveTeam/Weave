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

package weave.visualization.plotters
{
	import weave.api.linkSessionState;
	import weave.api.primitives.IBounds2D;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	
	/**
	 * PieChartPlotter
	 * 
	 * @author hbyrne
	 * @author abaumann
	 * @author adufilie
	 */
	public class PieChartPlotter_old extends AbstractSimplifiedPlotter
	{
		
		public function PieChartPlotter_old()
		{
			super(WedgePlotter);
			init();
		}
		
		private function init():void
		{
			//working code:
			// define an equation to calculate the beginRadians based on the running total of a spanRadians variable
			var beginRadiansEquation:EquationColumn = wedgePlotter.beginRadians.requestLocalObject(EquationColumn, false);
			beginRadiansEquation.equation.value = "0.5 * PI + getRunningTotal(spanRadians) - getNumber(spanRadians)";
			// spanRadians variable must be same type as wedgePlotter.spanRadians in order to link them
			var spanRadiansVariable:DynamicColumn = beginRadiansEquation.requestVariable("spanRadians", DynamicColumn);
			// link wedgePlotter.spanRadians with the spanRadians variable
			linkSessionState(spanRadiansVariable, wedgePlotter.spanRadians);

			//------------ this code causes each pie slice to be offset by the size of itself
//			// the beginRadians is the running total of the spanRadians
//			var runningTotal:RunningTotalColumn = wedgePlotter.beginRadians.initObject(RunningTotalColumn) as RunningTotalColumn;
//			// link the internal column of runningTotal to the internal column of spanRadians
//			linkSessionState(runningTotal, wedgePlotter.spanRadians);
			//------------

			// the spanRadians is the percentage of the sum times 2*PI
			var sliceEquationCol:EquationColumn = wedgePlotter.spanRadians.requestLocalObject(EquationColumn, false);
			sliceEquationCol.equation.value = "getNumber(x) / getSum(x) * 2 * PI";
			// _sliceSizeCol is the variable inside the equation.
			_sliceSizeCol = sliceEquationCol.requestVariable("x", DynamicColumn);
			
			
			registerSpatialProperties(sliceSize, keySet);
		}
		
		private var _sliceSizeCol:DynamicColumn;

		private function get wedgePlotter():WedgePlotter { return internalPlotter as WedgePlotter; }

		public function get sliceSize():DynamicColumn {	return _sliceSizeCol; }

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			return getReusableBounds(-1, -1, 1, 1);
		}
	}
}
