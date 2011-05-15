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

package org.oicweave.visualization.plotters
{
	import flash.display.Graphics;
	import flash.display.Shape;
	
	import org.oicweave.Weave;
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.linkSessionState;
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.data.AttributeColumns.DynamicColumn;
	import org.oicweave.data.AttributeColumns.EquationColumn;
	import org.oicweave.data.AttributeColumns.FilteredColumn;
	import org.oicweave.data.AttributeColumns.SortedColumn;
	import org.oicweave.primitives.Bounds2D;
	import org.oicweave.visualization.plotters.styles.DynamicFillStyle;
	import org.oicweave.visualization.plotters.styles.DynamicLineStyle;
	import org.oicweave.visualization.plotters.styles.SolidFillStyle;
	import org.oicweave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * PieChartPlotter
	 * 
	 * @author adufilie
	 */
	public class PieChartPlotter extends AbstractPlotter
	{
		public function PieChartPlotter()
		{
			init();
		}
		
		private var _beginRadians:EquationColumn;
		private var _spanRadians:EquationColumn;
		private var _filteredData:FilteredColumn;
		public function get data():DynamicColumn { return _filteredData.internalDynamicColumn; }
		
		public const lineStyle:DynamicLineStyle = new DynamicLineStyle(SolidLineStyle);
		public const fillStyle:DynamicFillStyle = new DynamicFillStyle(SolidFillStyle);
		
		private function init():void
		{
			var fill:SolidFillStyle = fillStyle.internalObject as SolidFillStyle;
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			
			_beginRadians = new EquationColumn();
			_beginRadians.equation.value = "0.5 * PI + getRunningTotal(spanRadians) - getNumber(spanRadians)";
			_spanRadians = _beginRadians.requestVariable("spanRadians", EquationColumn, true);
			_spanRadians.equation.value = "getNumber(sortedData) / getSum(sortedData) * 2 * PI";
			var sortedData:SortedColumn = _spanRadians.requestVariable("sortedData", SortedColumn, true);
			_filteredData = sortedData.internalDynamicColumn.requestLocalObject(FilteredColumn, true);
			linkSessionState(keySet.keyFilter, _filteredData.filter);
			
			registerSpatialProperties(data);
			registerNonSpatialProperties(fillStyle, lineStyle);
			setKeySource(_filteredData);
		}

		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			// project data coordinates to screen coordinates and draw graphics
			var beginRadians:Number = _beginRadians.getValueFromKey(recordKey, Number) as Number;
			var spanRadians:Number = _spanRadians.getValueFromKey(recordKey, Number) as Number;
			
			var graphics:Graphics = tempShape.graphics;
			// begin line & fill
			lineStyle.beginLineStyle(recordKey, graphics);				
			fillStyle.beginFillStyle(recordKey, graphics);
			// move to center point
			WedgePlotter.drawProjectedWedge(graphics, dataBounds, screenBounds, beginRadians, spanRadians);
			// end fill
			graphics.endFill();
		}
		
		/**
		 * This gets the data bounds of the bin that a record key falls into.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var beginRadians:Number = _beginRadians.getValueFromKey(recordKey, Number) as Number;
			var spanRadians:Number = _spanRadians.getValueFromKey(recordKey, Number) as Number;
			var bounds:IBounds2D = getReusableBounds();
			WedgePlotter.getWedgeBounds(bounds, beginRadians, spanRadians);
			return [bounds];
		}
		
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
