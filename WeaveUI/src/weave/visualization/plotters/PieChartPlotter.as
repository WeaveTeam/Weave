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
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import mx.controls.Alert;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.primitives.IBounds2D;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.SortedColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.visualization.plotters.styles.DynamicFillStyle;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
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
		private var _labelColumn:DynamicColumn = new DynamicColumn();
		
		public function get data():DynamicColumn { return _filteredData.internalDynamicColumn; }
		public function get label():DynamicColumn {return _labelColumn;}
		
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
			registerNonSpatialProperties(fillStyle, lineStyle, label);
			setKeySource(_filteredData);
		}

		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			// project data coordinates to screen coordinates and draw graphics
			var beginRadians:Number = _beginRadians.getValueFromKey(recordKey, Number);
			var spanRadians:Number = _spanRadians.getValueFromKey(recordKey, Number);
			
			var graphics:Graphics = tempShape.graphics;
			// begin line & fill
			lineStyle.beginLineStyle(recordKey, graphics);				
			fillStyle.beginFillStyle(recordKey, graphics);
			// move to center point
			WedgePlotter.drawProjectedWedge(graphics, dataBounds, screenBounds, beginRadians, spanRadians);
			// end fill
			graphics.endFill();
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (_labelColumn.keys.length == 0) return;
				
			var recordKey:IQualifiedKey;
			var beginRadians:Number;
			var spanRadians:Number;
			var midRadians:Number;
			var xScreenRadius:Number;
			var yScreenRadius:Number;
			var coordinate:Point = new Point();
			
			for (var i:int ; i < _filteredData.keys.length ; i++)
			{
				if (_labelColumn.containsKey(_filteredData.keys[i] as IQualifiedKey) == false) return;
				recordKey = _filteredData.keys[i] as IQualifiedKey;
				beginRadians = _beginRadians.getValueFromKey(recordKey, Number) as Number;
				spanRadians = _spanRadians.getValueFromKey(recordKey, Number) as Number;
				midRadians = beginRadians + (spanRadians / 2);
				
				coordinate.x = Math.cos(midRadians);
				coordinate.y = Math.sin(midRadians);
				dataBounds.projectPointTo(coordinate, screenBounds);
				coordinate.x += Math.cos(midRadians) * 10 * screenBounds.getXDirection();
				coordinate.y += Math.sin(midRadians) * 10 * screenBounds.getYDirection();
				
				var labelText:BitmapText = new BitmapText();
				labelText.text = ("  " + _labelColumn.getValueFromKey((_filteredData.keys[i] as IQualifiedKey)) + "  ");
				if (midRadians < (Math.PI / 2) || midRadians > ((3 * Math.PI) / 2))
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
				}
				else if (midRadians == ((3 * Math.PI) / 2))
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
				}
				else if (midRadians == (Math.PI / 2))
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_BOTTOM ;
				}
				else
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
				}
				
				labelText.textFormat.color=Weave.properties.axisFontColor.value;
				labelText.textFormat.size=Weave.properties.axisFontSize.value;
				labelText.textFormat.underline=Weave.properties.axisFontUnderline.value;
				labelText.x = coordinate.x;
				labelText.y = coordinate.y;
				labelText.draw(destination);
			}
		}
		
		/**
		 * This gets the data bounds of the bin that a record key falls into.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var beginRadians:Number = _beginRadians.getValueFromKey(recordKey, Number);
			var spanRadians:Number = _spanRadians.getValueFromKey(recordKey, Number);
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
