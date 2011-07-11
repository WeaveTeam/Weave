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
	import flash.geom.Point;
	import flash.text.TextFormatAlign;
	
	import mx.formatters.NumberFormatter;
	import mx.utils.NameUtil;
	
	import weave.Weave;
	import weave.WeaveProperties;
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.linkSessionState;
	import weave.api.primitives.IBounds2D;
	import weave.compiler.MathLib;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	import weave.primitives.LinkableBounds2D;
	import weave.primitives.LinkableNumberFormatter;
	import weave.primitives.LooseAxisDescription;
	import weave.utils.BitmapText;
	
	public class AxisPlotter extends AbstractPlotter
	{
		public function AxisPlotter()
		{
			init();
		}
		
		private function init():void
		{
			linkSessionState(Weave.properties.axisFontFamily, axisFontFamily);
			linkSessionState(Weave.properties.axisFontColor, axisFontColor);
			linkSessionState(Weave.properties.axisFontSize, axisFontSize);
			linkSessionState(Weave.properties.axisFontBold, axisFontBold);
			linkSessionState(Weave.properties.axisFontItalic, axisFontItalic);
			linkSessionState(Weave.properties.axisFontUnderline, axisFontUnderline);
			spatialCallbacks.addImmediateCallback(this, updateLabels);

			// set defaults so something will show if these values are not set
			axisLineDataBounds.setBounds(-1, -1, 1, 1);
			axisLineMinValue.value = -1;
			axisLineMaxValue.value = 1;
			
			setKeySource(_keySet);
		}
		
		//TODO: put this huge list of properties into a separate object instead
		public const axisFontFamily:LinkableString = registerNonSpatialProperty(new LinkableString(WeaveProperties.DEFAULT_FONT_FAMILY, WeaveProperties.verifyFontFamily));
		public const axisFontBold:LinkableBoolean = registerNonSpatialProperty(new LinkableBoolean(true));
		public const axisFontItalic:LinkableBoolean = registerNonSpatialProperty(new LinkableBoolean(false));
		public const axisFontUnderline:LinkableBoolean = registerNonSpatialProperty(new LinkableBoolean(false));
		public const axisFontSize:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(10));
		public const axisFontColor:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(0x000000));
		public const axisLabelDistance:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(-10));
		public const axisLabelRelativeAngle:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(-45));
		public const axisGridLineThickness:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(1));
		public const axisGridLineColor:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(0xDDDDDD));
		public const axisGridLineAlpha:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(1));
		
		// the axis line beginning and end data coordinates
		public const axisLineDataBounds:LinkableBounds2D = newSpatialProperty(LinkableBounds2D);
		// the value corresponding to the beginning of the axis line
		public const axisLineMinValue:LinkableNumber = newSpatialProperty(LinkableNumber);
		// the value corresponding to the end of the axis line
		public const axisLineMaxValue:LinkableNumber = newSpatialProperty(LinkableNumber);
		// the value corresponding to the beginning of the axis line.  If not specified, axisLineMinValue will be used.
		public const tickMinValue:LinkableNumber = newSpatialProperty(LinkableNumber);
		// the value corresponding to the end of the axis line.  If not specified, axisLineMaxValue will be used.
		public const tickMaxValue:LinkableNumber = newSpatialProperty(LinkableNumber);
		
		// show or hide the axis name
		public const showAxisName:LinkableBoolean = registerNonSpatialProperty(new LinkableBoolean(true));
		// number of requested tick marks
		public const tickCountRequested:LinkableNumber = registerSpatialProperty(new LinkableNumber(10));
		// This option forces the axis to generate the exact number of requested tick marks between tick min and max values (inclusive)
		public const forceTickCount:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));

		public const axisTickLength:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(10));
		public const axisTickThickness:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(2));
		
		public const axisLineColor:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(0x000000));
		public const axisLineAlpha:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(1));
		public const axisTickColor:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(0x000000));
		public const axisTickAlpha:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(1));
		public const axisLineThickness:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(2));
		
		// formatter to use when generating tick mark labels
		public const labelNumberFormatter:LinkableNumberFormatter = newNonSpatialProperty(LinkableNumberFormatter);
		public const labelTextAlignment:LinkableString = newNonSpatialProperty(LinkableString);
		public const labelHorizontalAlign:LinkableString = newNonSpatialProperty(LinkableString);
		public const labelVerticalAlign:LinkableString = newNonSpatialProperty(LinkableString);
		public const labelDistanceIsVertical:LinkableBoolean = newNonSpatialProperty(LinkableBoolean);

		private const _keySet:KeySet = newSpatialProperty(KeySet); // stores tick mark keys
		private const _axisDescription:LooseAxisDescription = new LooseAxisDescription(); // calculates tick marks
		private const _bitmapText:BitmapText = new BitmapText(); // for drawing text
		private var _xDataTickDelta:Number; // x distance between ticks
		private var _yDataTickDelta:Number; // y distance between ticks
		private const MIN_LABEL_KEY:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(null, 'minLabel');
		private const MAX_LABEL_KEY:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(null, 'maxLabel');
		private const _numberFormatter:NumberFormatter = new NumberFormatter();
		
		public var showRealMinAndMax:Boolean = false;

		// validates tick mark variables		
		public function updateLabels():void
		{
			var cc:CallbackCollection;
			var callbackCollections:Array = [getCallbackCollection(this), spatialCallbacks];

			// make sure callbacks only run once
			for each (cc in callbackCollections)
				cc.delayCallbacks();
			
			var minValue:Number = tickMinValue.value;
			var maxValue:Number = tickMaxValue.value;
			if (isNaN(minValue))
				minValue = axisLineMinValue.value;
			if (isNaN(maxValue))
				maxValue = axisLineMaxValue.value;
				
			_axisDescription.setup(minValue, maxValue, tickCountRequested.value, forceTickCount.value);
			
			
			labelNumberFormatter.precision.value = _axisDescription.numberOfDigits;
			
			var newKeys:Array = showRealMinAndMax ? [MIN_LABEL_KEY] : [];
			for (var i:int = 0; i < _axisDescription.numberOfTicks; i++)
			{
				// only include tick marks that are between min,max values
				var tickValue:Number = _axisDescription.tickMin + i * _axisDescription.tickDelta;
				if (axisLineMinValue.value <= tickValue && tickValue <= axisLineMaxValue.value)
					newKeys.push(WeaveAPI.QKeyManager.getQKey(null, String(i)));
			}
			if(showRealMinAndMax)
				newKeys.push(MAX_LABEL_KEY);
			
			var keysChanged:Boolean = _keySet.replaceKeys(newKeys);
			
			// allow callbacks to run now
			for each (cc in callbackCollections)
				cc.resumeCallbacks();
		}
		
		/**
		 * @param recordKey The key associated with a tick mark
		 * @param outputPoint A place to store the data coordinates of the tick mark
		 * @return The value associated with the tick mark
		 */
		private function getTickValueAndDataCoords(recordKey:IQualifiedKey, outputPoint:Point):Number
		{
			var _axisLineMinValue:Number = axisLineMinValue.value;
			var _axisLineMaxValue:Number = axisLineMaxValue.value;
			
			var tickValue:Number;
			// special case for min,max labels
			if (recordKey == MIN_LABEL_KEY)
			{
				tickValue = _axisLineMinValue;
				outputPoint.x = axisLineDataBounds.xMin.value;
				outputPoint.y = axisLineDataBounds.yMin.value;
			}
			else if (recordKey == MAX_LABEL_KEY)
			{
				tickValue = _axisLineMaxValue;
				outputPoint.x = axisLineDataBounds.xMax.value;
				outputPoint.y = axisLineDataBounds.yMax.value;
			}
			else
			{
				var tickIndex:int = parseInt(recordKey.localName);
				tickValue = _axisDescription.tickMin + tickIndex * _axisDescription.tickDelta;
				outputPoint.x = MathLib.scale(tickValue, _axisLineMinValue, _axisLineMaxValue, axisLineDataBounds.xMin.value, axisLineDataBounds.xMax.value);
				outputPoint.y = MathLib.scale(tickValue, _axisLineMinValue, _axisLineMaxValue, axisLineDataBounds.yMin.value, axisLineDataBounds.yMax.value);
			}
			
			return tickValue;
		}
		
		// gets the bounds of a tick mark
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			getTickValueAndDataCoords(recordKey, tempPoint);
			var bounds:IBounds2D = getReusableBounds();
			bounds.setCenteredRectangle(tempPoint.x, tempPoint.y, 0, 0);
			return [bounds];
		}
		
		// draws the tick marks
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
//			if (recordKeys.length == 0)
//				trace(this,'drawPlot',arguments);
			
			initPrivateAxisLineBoundsVariables(dataBounds, screenBounds);
			// everything below is in screen coordinates

			// get the angle of the axis line (relative to real screen coordinates, positive Y in downward direction)
			var axisAngle:Number = Math.atan2(_axisLineScreenBounds.getHeight(), _axisLineScreenBounds.getWidth());
			// ticks are perpendicular to axis line
			var tickAngle:Number = axisAngle + Math.PI / 2;
			// label angle is relative to axis angle
			var labelAngle:Number = axisAngle + axisLabelRelativeAngle.value * Math.PI / 180; // convert from degrees to radians

			// calculate tick line offset from angle
			var xTickOffset:Number = Math.cos(tickAngle) * axisTickLength.value / 2;
			var yTickOffset:Number = Math.sin(tickAngle) * axisTickLength.value / 2;
			
			// calculate label offset from angle
			var _labelDistance:Number = axisLabelDistance.value;
			var labelAngleOffset:Number = labelDistanceIsVertical.value ? Math.PI / 2: 0;
			var xLabelOffset:Number = Math.cos(labelAngle + labelAngleOffset) * axisLabelDistance.value;
			var yLabelOffset:Number = Math.sin(labelAngle + labelAngleOffset) * axisLabelDistance.value;
			
			setupBitmapText();
			_bitmapText.maxWidth = 80; // TEMPORARY SOLUTION (for word wrap)
			
			// calculate the distance between tick marks to use as _bitmapText.maxHeight
			var lineLength:Number = Math.sqrt(Math.pow(_axisLineScreenBounds.getWidth(), 2) + Math.pow(_axisLineScreenBounds.getHeight(), 2));
			var tickScreenDelta:Number = lineLength / (_axisDescription.numberOfTicks - 1);
			tickScreenDelta /= Math.SQRT2; // TEMPORARY SOLUTION -- assumes text is always at 45 degree angle
			_bitmapText.maxHeight = tickScreenDelta;

			_bitmapText.angle = labelAngle * 180 / Math.PI; // convert from radians to degrees
			
			// init number formatter for beginning & end tick marks
			labelNumberFormatter.copyTo(_numberFormatter);
			
			var graphics:Graphics = tempShape.graphics;
			for (var i:int = 0; i < recordKeys.length; i++)
			{
				var key:IQualifiedKey = recordKeys[i] as IQualifiedKey;

				// get screen coordinates of tick mark
				var tickValue:Number = getTickValueAndDataCoords(key, tempPoint);
								
				_axisLineDataBounds.projectPointTo(tempPoint, _axisLineScreenBounds);
				var xTick:Number = tempPoint.x;
				var yTick:Number = tempPoint.y;
				
				// draw tick mark line
				graphics.clear();
				graphics.lineStyle(axisTickThickness.value, axisTickColor.value, axisTickAlpha.value);
				
				if ( key == MIN_LABEL_KEY || key == MAX_LABEL_KEY )
				{
					graphics.moveTo(xTick - xTickOffset*2, yTick - yTickOffset*2);
					graphics.lineTo(xTick + xTickOffset*2, yTick + yTickOffset*2);
				}
				else
				{
					graphics.moveTo(xTick - xTickOffset, yTick - yTickOffset);
					graphics.lineTo(xTick + xTickOffset, yTick + yTickOffset);
				}
				destination.draw(tempShape);
				
				// draw tick mark label
				_bitmapText.text = null;
				// attempt to use label function
				var labelFunctionResult:String = _labelFunction == null ? null : _labelFunction(tickValue);
				if (_labelFunction != null && labelFunctionResult != null)
				{
					_bitmapText.text = labelFunctionResult;
				}
				else if (key == MIN_LABEL_KEY || key == MAX_LABEL_KEY )
				{
					if (tickValue == int(tickValue))
						_numberFormatter.precision = -1;
					else
						_numberFormatter.precision = 2;
					
					_bitmapText.text = _numberFormatter.format(tickValue);
				}
				else
				{
					_bitmapText.text = labelNumberFormatter.format(tickValue);
				}
				

				_bitmapText.x = xTick + xLabelOffset;
				_bitmapText.y = yTick + yLabelOffset;
				_bitmapText.draw(destination);
			}
		}
		
		private var _titleBounds:IBounds2D = null;
		public function getTitleLabelBounds():IBounds2D
		{
			return _titleBounds;
		}
		
		public static const LABEL_POSITION_AT_AXIS_MIN:String  		= "AxisPlotter.LABEL_POSITION_AT_AXIS_MIN";
		public static const LABEL_POSITION_AT_AXIS_CENTER:String    = "AxisPlotter.LABEL_POSITION_AT_AXIS_CENTER";
		public static const LABEL_POSITION_AT_AXIS_MAX:String  		= "AxisPlotter.LABEL_POSITION_AT_AXIS_MAX";
		
		public static const LABEL_LEFT_JUSTIFIED:String 	= BitmapText.HORIZONTAL_ALIGN_LEFT;
		public static const LABEL_CENTERED:String 			= BitmapText.HORIZONTAL_ALIGN_CENTER;
		public static const LABEL_RIGHT_JUSTIFIED:String 	= BitmapText.HORIZONTAL_ALIGN_RIGHT;
		
		// BEGIN TEMPORARY SOLUTION
		public function setSideAxisName(name:String, angle:Number, xDistance:Number, yDistance:Number, verticalAlign:String, 
									    labelPosition:String = LABEL_POSITION_AT_AXIS_CENTER, labelAlignment:String = null,
									    maxLabelWidth:int = -1):void
		{
			_axisName = name;
			_axisNameAngle = angle;
			_axisNameXDistance = xDistance;
			_axisNameYDistance = yDistance;
			_axisNameVerticalAlign = verticalAlign;
			_labelPosition = labelPosition;
			_labelAlignment = labelAlignment;
			_maxLabelWidth = maxLabelWidth;
			
			getCallbackCollection(this).triggerCallbacks();
		}
		private var _axisName:String;
		private var _axisNameAngle:Number;
		private var _axisNameXDistance:Number;
		private var _axisNameYDistance:Number;
		private var _axisNameVerticalAlign:String;
		private var _labelPosition:String;
		private var _labelAlignment:String;
		private var _maxLabelWidth:int;
		// END TEMPORARY SOLUTION
		
		// draws the axis line
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			setupAxisNameBitmapText(dataBounds,screenBounds);
			
			// draw the axis line
			var graphics:Graphics = tempShape.graphics;
			graphics.clear();
			graphics.lineStyle(axisLineThickness.value, axisLineColor.value, axisLineAlpha.value);
			graphics.moveTo(_axisLineScreenBounds.xMin, _axisLineScreenBounds.yMin);
			graphics.lineTo(_axisLineScreenBounds.xMax, _axisLineScreenBounds.yMax);
			destination.draw(tempShape);
			if (showAxisName.value && _axisName != null)
			{
//				getAxisNameScreenBounds(dataBounds,screenBounds,_tempBounds);
//				destination.fillRect(new Rectangle(_tempBounds.xMin,_tempBounds.yMin,_tempBounds.width,_tempBounds.height),0x80FF0000);
				_bitmapText.draw(destination);
			}
		}
		
		public var name:String = NameUtil.createUniqueName(this);
		
		private const _tempBounds:IBounds2D = new Bounds2D();
		
		protected function setupBitmapText():void
		{
			_bitmapText.textFormat.font = axisFontFamily.value;
			_bitmapText.textFormat.size = axisFontSize.value;
			_bitmapText.textFormat.color = axisFontColor.value;
			_bitmapText.textFormat.bold = axisFontBold.value;
			_bitmapText.textFormat.italic = axisFontItalic.value;
			_bitmapText.textFormat.underline = axisFontUnderline.value;
			try {
				_bitmapText.textFormat.align = labelTextAlignment.value;
			} catch (e:Error) { }
			
			_bitmapText.horizontalAlign = labelHorizontalAlign.value;
			_bitmapText.verticalAlign = labelVerticalAlign.value;
		}
		
		protected function setupAxisNameBitmapText(dataBounds:IBounds2D, screenBounds:IBounds2D):void
		{
			initPrivateAxisLineBoundsVariables(dataBounds, screenBounds);

			//trace(dataBounds, screenBounds);

			// BEGIN TEMPORARY SOLUTION -- setup BitmapText for axis name
			if (_axisName != null)
			{
				setupBitmapText();
				_bitmapText.text = _axisName;
				_bitmapText.angle = _axisNameAngle;
				_bitmapText.textFormat.align = TextFormatAlign.LEFT;
				_bitmapText.verticalAlign = _axisNameAngle == 0 ? BitmapText.VERTICAL_ALIGN_BOTTOM : BitmapText.VERTICAL_ALIGN_TOP;
				_bitmapText.maxWidth = _axisNameAngle == 0 ? screenBounds.getXCoverage() : screenBounds.getYCoverage();
				_bitmapText.maxHeight = 40; // temporary solution
				
				if(_maxLabelWidth != -1)
					_bitmapText.maxWidth = _maxLabelWidth;
				
				if(_labelPosition == LABEL_POSITION_AT_AXIS_MIN)
				{
					_bitmapText.x = _axisLineScreenBounds.xMin + _axisNameXDistance;
					_bitmapText.y = _axisLineScreenBounds.yMin + _axisNameYDistance;
					_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT;
				}
				if(_labelPosition == LABEL_POSITION_AT_AXIS_MAX)
				{
					_bitmapText.x = _axisLineScreenBounds.xMax + _axisNameXDistance;
					_bitmapText.y = _axisLineScreenBounds.yMax + _axisNameYDistance;
					_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT;
				}
				if(_labelPosition == LABEL_POSITION_AT_AXIS_CENTER)
				{
					_bitmapText.x = _axisLineScreenBounds.getXCenter() + _axisNameXDistance;
					_bitmapText.y = _axisLineScreenBounds.getYCenter() + _axisNameYDistance;
					_bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
				}
				
				if(_labelAlignment)
					_bitmapText.horizontalAlign = _labelAlignment;

				//_titleBounds = new Bounds2D(_bitmapText.x, _bitmapText.y, _bitmapText.width + _bitmapText.x, _bitmapText.height + _bitmapText.y)

			}
			// END TEMPORARY SOLUTION
		}
		
//		public function getAxisNameScreenBounds(dataBounds:IBounds2D, screenBounds:IBounds2D,outputScreenBounds:IBounds2D):void
//		{
//			setupAxisNameBitmapText(dataBounds,screenBounds);
//			// this does not work when text is vertical
//			_bitmapText.getUnrotatedBounds(outputScreenBounds);
//		}
		
		// gets the bounds of the axis line
		override public function getBackgroundDataBounds():IBounds2D
		{
			var bounds:IBounds2D = getReusableBounds();
			axisLineDataBounds.copyTo(bounds);
			return bounds;
		}
		
		private function initPrivateAxisLineBoundsVariables(dataBounds:IBounds2D, screenBounds:IBounds2D):void
		{
			// get axis line data bounds and project to screen coordinates
			axisLineDataBounds.copyTo(_axisLineDataBounds);
			// project to screen coords
			_axisLineScreenBounds.copyFrom(_axisLineDataBounds);
			dataBounds.projectCoordsTo(_axisLineScreenBounds, screenBounds);
		}

		private const _axisLineDataBounds:Bounds2D = new Bounds2D();
		private const _axisLineScreenBounds:Bounds2D = new Bounds2D();
		private const tempPoint:Point = new Point();
		private const tempPoint2:Point = new Point();

		// TEMPORARY SOLUTION
		public function setLabelFunction(func:Function):void
		{
			_labelFunction = func;
			getCallbackCollection(this).triggerCallbacks();
		}
		private var _labelFunction:Function = null;
		// END TEMPORARY SOLUTION
	}
}
