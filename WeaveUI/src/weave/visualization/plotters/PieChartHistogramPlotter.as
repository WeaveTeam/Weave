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
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableNumber;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.StringLookupColumn;
	import weave.primitives.ColorRamp;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.visualization.plotters.styles.DynamicFillStyle;
	import weave.visualization.plotters.styles.DynamicLineStyle;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * PieChartHistogramPlotter
	 * 
	 * @author adufilie
	 */
	public class PieChartHistogramPlotter extends AbstractPlotter
	{
		public function PieChartHistogramPlotter()
		{
			init();
		}
		
		private var _beginRadians:EquationColumn;
		private var _spanRadians:EquationColumn;
		private var _binLookup:StringLookupColumn;
		private var _binnedData:BinnedColumn;
		private var _filteredData:FilteredColumn;
		public const chartColors:ColorRamp = registerNonSpatialProperty(new ColorRamp(ColorRamp.getColorRampXMLByName("Doppler Radar"))); // bars get their color from here
		
		public function get binnedData():BinnedColumn { return _binnedData; }
		
		public function get unfilteredData():DynamicColumn { return _filteredData.internalDynamicColumn; }
		public const lineStyle:DynamicLineStyle = registerNonSpatialProperty(new DynamicLineStyle(SolidLineStyle));
		public const fillStyle:DynamicFillStyle = registerNonSpatialProperty(new DynamicFillStyle(SolidFillStyle));
		public const labelAngleRatio:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(0, verifyLabelAngleRatio));
		
		private function verifyLabelAngleRatio(value:Number):Boolean
		{
			return 0 <= value && value <= 1;
		}
		
		private function init():void
		{
			(fillStyle.internalObject as SolidFillStyle).color.defaultValue.setSessionState(0x808080);
			
			_beginRadians = newDisposableChild(this, EquationColumn);
			_beginRadians.equation.value = "0.5 * PI + getRunningTotal(spanRadians) - getNumber(spanRadians)";
			_spanRadians = _beginRadians.requestVariable("spanRadians", EquationColumn, true);
			_spanRadians.equation.value = "getNumber(binSize) / getSum(binSize) * 2 * PI";
			var binSize:EquationColumn = _spanRadians.requestVariable("binSize", EquationColumn, true);
			binSize.equation.value = "arrayLength(getValue(binLookup))";
			_binLookup = binSize.requestVariable("binLookup", StringLookupColumn, true);
			_binnedData = _binLookup.requestLocalObject(BinnedColumn, true);
			_filteredData = binnedData.internalDynamicColumn.requestLocalObject(FilteredColumn, true);
			linkSessionState(keySet.keyFilter, _filteredData.filter);
			registerSpatialProperties(_binnedData);
			setKeySource(_filteredData);
			
			registerNonSpatialProperties(
				Weave.properties.axisFontSize,
				Weave.properties.axisFontColor
			);
		}
		
		/**
		 * This draws the histogram bins that a list of record keys fall into.
		 */
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// convert record keys to bin keys
			// save a mapping of each bin key found to a value of true
			var binKeyMap:Dictionary = new Dictionary();
			for (var i:int = 0; i < recordKeys.length; i++)
				binKeyMap[ _binLookup.getStringLookupKeyFromInternalColumnKey(recordKeys[i]) ] = true;
			
			var binKeys:Array = [];
			for (var binQKey:* in binKeyMap)
				binKeys.push(binQKey);
			
			// draw the bins
			super.drawPlot(binKeys, dataBounds, screenBounds, destination);
		}
		
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			// project data coordinates to screen coordinates and draw graphics
			var beginRadians:Number = _beginRadians.getValueFromKey(recordKey, Number);
			var spanRadians:Number = _spanRadians.getValueFromKey(recordKey, Number);
			
			var graphics:Graphics = tempShape.graphics;
			// begin line & fill
			lineStyle.beginLineStyle(recordKey, graphics);				
			//fillStyle.beginFillStyle(recordKey, graphics);
			
			// draw graphics
			var color:Number = chartColors.getColorFromNorm( ColumnUtils.getNorm(_binLookup, recordKey) );
			graphics.beginFill(color, 1);
			
			// move to center point
			WedgePlotter.drawProjectedWedge(graphics, dataBounds, screenBounds, beginRadians, spanRadians);
			// end fill
			graphics.endFill();
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (_filteredData.keys.length == 0)
				return;
			
			var binKey:IQualifiedKey;
			var beginRadians:Number;
			var spanRadians:Number;
			var midRadians:Number;
			var xScreenRadius:Number;
			var yScreenRadius:Number;
			
			var binKeyMap:Dictionary = new Dictionary();
			for (var j:int = 0; j < _filteredData.keys.length; j++)
				binKeyMap[ _binLookup.getStringLookupKeyFromInternalColumnKey(_filteredData.keys[j] as IQualifiedKey)] = true;
			
			var binKeys:Array = [];
			for (var binQKey:* in binKeyMap)
				binKeys.push(binQKey);
			
			for (var i:int; i < binKeys.length; i++)
			{
				binKey = binKeys[i] as IQualifiedKey;
				beginRadians = _beginRadians.getValueFromKey(binKey, Number) as Number;
				spanRadians = _spanRadians.getValueFromKey(binKey, Number) as Number;
				midRadians = beginRadians + (spanRadians / 2);
				
				var cos:Number = Math.cos(midRadians);
				var sin:Number = Math.sin(midRadians);
				
				_tempPoint.x = cos;
				_tempPoint.y = sin;
				dataBounds.projectPointTo(_tempPoint, screenBounds);
				_tempPoint.x += cos * 10 * screenBounds.getXDirection();
				_tempPoint.y += sin * 10 * screenBounds.getYDirection();
				
				_bitmapText.text = binKey.localName;
				
				_bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER;
				
				_bitmapText.angle = screenBounds.getYDirection() * (midRadians * 180 / Math.PI);
				_bitmapText.angle = (_bitmapText.angle % 360 + 360) % 360;
				if (cos > -0.000001) // the label exactly at the bottom will have left align
				{
					_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT;
					// first get values between -90 and 90, then multiply by the ratio
					_bitmapText.angle = ((_bitmapText.angle + 90) % 360 - 90) * labelAngleRatio.value;
				}
				else
				{
					_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT;
					// first get values between -90 and 90, then multiply by the ratio
					_bitmapText.angle = (_bitmapText.angle - 180) * labelAngleRatio.value;
				}
				_bitmapText.textFormat.size = Weave.properties.axisFontSize.value;
				_bitmapText.textFormat.color = Weave.properties.axisFontColor.value;
				_bitmapText.x = _tempPoint.x;
				_bitmapText.y = _tempPoint.y;
				_bitmapText.draw(destination);
			}
		}
		
		private const _tempPoint:Point = new Point();
		private const _bitmapText:BitmapText = new BitmapText();
		
		/**
		 * This gets the data bounds of the bin that a record key falls into.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var binKey:IQualifiedKey = _binLookup.getStringLookupKeyFromInternalColumnKey(recordKey);
			var beginRadians:Number = _beginRadians.getValueFromKey(binKey, Number);
			var spanRadians:Number = _spanRadians.getValueFromKey(binKey, Number);
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
