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
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.geom.Point;
	import flash.text.TextFormatAlign;
	
	import mx.formatters.NumberFormatter;
	
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotTask;
	import weave.compiler.StandardLib;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableFunction;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	import weave.primitives.LinkableBounds2D;
	import weave.primitives.LinkableNumberFormatter;
	import weave.primitives.LooseAxisDescription;
	import weave.utils.BitmapText;
	import weave.utils.LinkableTextFormat;
	
	public class SimpleAxisPlotter extends AbstractPlotter
	{
		public function SimpleAxisPlotter()
		{
			//TODO: this list of properties should be contained in a separate object so we don't have to list them all here
			spatialCallbacks.addImmediateCallback(this, updateLabels);
			registerLinkableChild(this, LinkableTextFormat.defaultTextFormat);
			
			setSingleKeySource(_keySet);
		}
		
		public const axisLabelDistance:LinkableNumber = registerLinkableChild(this, new LinkableNumber(-10, isFinite));
		public const axisLabelRelativeAngle:LinkableNumber = registerLinkableChild(this, new LinkableNumber(-45, isFinite));
		public const axisGridLineThickness:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1, isFinite));
		public const axisGridLineColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0xDDDDDD));
		public const axisGridLineAlpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1, isFinite));
		public const axesThickness:LinkableNumber = registerLinkableChild(this, new LinkableNumber(10, isFinite));
		public const axesColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0xB0B0B0, isFinite));
		public const axesAlpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1, isFinite));
		
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
		
		public const overrideAxisName:LinkableString = newLinkableChild(this, LinkableString);
		// show or hide the axis name
		public const showAxisName:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		// number of requested tick marks
		public const tickCountRequested:LinkableNumber = registerSpatialProperty(new LinkableNumber(10));
		// This option forces the axis to generate the exact number of requested tick marks between tick min and max values (inclusive)
		public const forceTickCount:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		
		public const showLabels:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const labelNumberFormatter:LinkableNumberFormatter = newLinkableChild(this, LinkableNumberFormatter); // formatter to use when generating tick mark labels
		public const labelTextAlignment:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_LEFT));
		public const labelHorizontalAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.HORIZONTAL_ALIGN_RIGHT));
		public const labelVerticalAlign:LinkableString = registerLinkableChild(this, new LinkableString(BitmapText.VERTICAL_ALIGN_MIDDLE));
		public const labelDistanceIsVertical:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const labelWordWrapSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(80));
		public const labelFunction:LinkableFunction = registerLinkableChild(this, new LinkableFunction('string', true, false, ['number', 'string']));
		
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
				var tickValue:Number = StandardLib.roundSignificant(_axisDescription.tickMin + i * _axisDescription.tickDelta);
				if (axisLineMinValue.value <= tickValue && tickValue <= axisLineMaxValue.value)
					newKeys.push(WeaveAPI.QKeyManager.getQKey(null, String(i)));
			}
			if (showRealMinAndMax)
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
			axisLineDataBounds.copyTo(_tempBounds);

			var tickValue:Number;
			// special case for min,max labels
			if (recordKey == MIN_LABEL_KEY)
			{
				tickValue = _axisLineMinValue;
				outputPoint.x = _tempBounds.xMin;
				outputPoint.y = _tempBounds.yMin;
			}
			else if (recordKey == MAX_LABEL_KEY)
			{
				tickValue = _axisLineMaxValue;
				outputPoint.x = _tempBounds.xMax;
				outputPoint.y = _tempBounds.yMax;
			}
			else
			{
				var tickIndex:int = parseInt(recordKey.localName);
				tickValue = StandardLib.roundSignificant(_axisDescription.tickMin + tickIndex * _axisDescription.tickDelta);
				outputPoint.x = StandardLib.scale(tickValue, _axisLineMinValue, _axisLineMaxValue, _tempBounds.xMin, _tempBounds.xMax);
				outputPoint.y = StandardLib.scale(tickValue, _axisLineMinValue, _axisLineMaxValue, _tempBounds.yMin, _tempBounds.yMax);
			}
			
			return tickValue;
		}
		
		/**
		 * gets the bounds of a tick mark 
		 * @param recordKey
		 * @return 
		 * 
		 */		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			getTickValueAndDataCoords(recordKey, tempPoint);
			var bounds:IBounds2D = getReusableBounds();
			bounds.setCenteredRectangle(tempPoint.x, tempPoint.y, 0, 0);
			return [bounds];
		}
		
		/**
		 * draws the grid lines (tick marks) 
		 */		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (!(task.asyncState is Function))
			{
				// these variables are used to save state between function calls
				var axisAngle:Number;			
				var tickAngle:Number;
				var labelAngle:Number;
				var xTickOffset:Number;
				var yTickOffset:Number;
				var _labelDistance:Number;
				var labelAngleOffset:Number;
				var xLabelOffset:Number;
				var yLabelOffset:Number;
				var lineLength:Number;
				var tickScreenDelta:Number;
				
				task.asyncState = function():Number
				{
					if (task.iteration == 0)
					{
						initPrivateAxisLineBoundsVariables(task.dataBounds, task.screenBounds);
						// everything below is in screen coordinates
			
						// get the angle of the axis line (relative to real screen coordinates, positive Y in downward direction)
						axisAngle = Math.atan2(_axisLineScreenBounds.getHeight(), _axisLineScreenBounds.getWidth());			
						// ticks are perpendicular to axis line
						tickAngle = axisAngle + Math.PI / 2;
						// label angle is relative to axis angle
						labelAngle = axisAngle + axisLabelRelativeAngle.value * Math.PI / 180; // convert from degrees to radians
			
						// calculate tick line offset from angle
						xTickOffset = Math.cos(tickAngle) * 10 / 2;
						yTickOffset = Math.sin(tickAngle) * 10 / 2;
						
						// calculate label offset from angle
						_labelDistance = axisLabelDistance.value;
						labelAngleOffset = labelDistanceIsVertical.value ? Math.PI / 2: 0;
						xLabelOffset = Math.cos(labelAngle + labelAngleOffset) * axisLabelDistance.value;
						yLabelOffset = Math.sin(labelAngle + labelAngleOffset) * axisLabelDistance.value;
						
						setupBitmapText();
						_bitmapText.maxWidth = labelWordWrapSize.value;
						
						// calculate the distance between tick marks to use as _bitmapText.maxHeight
						lineLength = Math.sqrt(Math.pow(_axisLineScreenBounds.getWidth(), 2) + Math.pow(_axisLineScreenBounds.getHeight(), 2));
						tickScreenDelta = lineLength / (_axisDescription.numberOfTicks - 1);
						tickScreenDelta /= Math.SQRT2; // TEMPORARY SOLUTION -- assumes text is always at 45 degree angle
						_bitmapText.maxHeight = tickScreenDelta;
			
						_bitmapText.angle = labelAngle * 180 / Math.PI; // convert from radians to degrees
						
						// init number formatter for beginning & end tick marks
						labelNumberFormatter.copyTo(_numberFormatter);
					}
					
					if (task.iteration < task.recordKeys.length)
					{
						var graphics:Graphics = tempShape.graphics;
						var key:IQualifiedKey = task.recordKeys[task.iteration] as IQualifiedKey;
		
						// get screen coordinates of tick mark
						var tickValue:Number = getTickValueAndDataCoords(key, tempPoint);
										
						_axisLineDataBounds.projectPointTo(tempPoint, _axisLineScreenBounds);
						var xTick:Number = tempPoint.x;
						var yTick:Number = tempPoint.y;
						
						// draw tick mark line and grid lines
						graphics.clear();
						graphics.lineStyle(axisGridLineThickness.value, axisGridLineColor.value, axisGridLineAlpha.value, false, LineScaleMode.NORMAL, CapsStyle.NONE);
						
						if (key == MIN_LABEL_KEY || key == MAX_LABEL_KEY)
						{
							graphics.moveTo(xTick - xTickOffset*2, yTick - yTickOffset*2);
							graphics.lineTo(xTick + xTickOffset*2, yTick + yTickOffset*2);
						}
						else if (axisAngle != 0)
						{
							graphics.moveTo(xTick-axesThickness.value, yTick);
							graphics.lineTo(xTick, yTick);
							graphics.moveTo(xTick, yTick);
							graphics.lineTo(task.screenBounds.getXMax(), yTick);
							
						}
						else if (axisAngle == 0)
						{
							var offset:Number = 1;
							graphics.moveTo(xTick, yTick + offset);
							graphics.lineTo(xTick, yTick+axesThickness.value + offset);
							graphics.moveTo(xTick, yTick);
							graphics.lineTo(xTick, task.screenBounds.getYMax());
							
						}
						task.buffer.draw(tempShape);
						
						// draw tick mark label
						if (showLabels.value)
						{
							_bitmapText.text = getLabel(tickValue);
							_bitmapText.x = xTick + xLabelOffset;
							_bitmapText.y = yTick + yLabelOffset;
							_bitmapText.draw(task.buffer);
						}
						return task.iteration / task.recordKeys.length;
					}
					
					return 1; // avoids divide-by-zero when there are no record keys
				}; // end task function
			} // end if
			
			return (task.asyncState as Function).apply(this, arguments);
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
		private function get axisName():String
		{
			return overrideAxisName.value || _axisName;
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
		
		/**
		 * draws the main axis line as a rectangle 
		 * @param dataBounds
		 * @param screenBounds
		 * @param destination
		 * 
		 */		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// draw the axis border
			if (axesThickness.value != 0)
			{
				initPrivateAxisLineBoundsVariables(dataBounds, screenBounds);
				var axisAngle:Number = Math.atan2(_axisLineScreenBounds.getHeight(), _axisLineScreenBounds.getWidth());
				var thickness:Number = axesThickness.value;
				var graphics:Graphics = tempShape.graphics;
				graphics.clear();
				graphics.lineStyle(0,0,0);
				graphics.beginFill(axesColor.value, axesAlpha.value);
				var xMin:Number = _axisLineScreenBounds.getXNumericMin();
				var yMin:Number = _axisLineScreenBounds.getYNumericMin();
				var yOffset:Number = 1;
				if (_axisLineScreenBounds.getXCoverage() == 0) // draw vertical rectangle to the left of the axis
				{
					graphics.drawRect(
						xMin - thickness,
						yMin,
						thickness,
						_axisLineScreenBounds.getYCoverage() + yOffset
					);
				}
				if (_axisLineScreenBounds.getYCoverage() == 0) // draw horizontal rectangle below axis
				{
					graphics.drawRect(
						xMin - thickness,
						yMin + yOffset,
						_axisLineScreenBounds.getXCoverage() + thickness,
						thickness
					);
				}
				graphics.endFill();
				destination.draw(tempShape);
			}
			if (showAxisName.value && axisName != null)
			{
				setupAxisNameBitmapText(dataBounds,screenBounds);
//				getAxisNameScreenBounds(dataBounds,screenBounds,_tempBounds);
//				destination.fillRect(new Rectangle(_tempBounds.xMin,_tempBounds.yMin,_tempBounds.width,_tempBounds.height),0x80FF0000);
				_bitmapText.draw(destination);
			}
		}
		
		private const _tempBounds:Bounds2D = new Bounds2D();
		
		protected function setupBitmapText():void
		{
			LinkableTextFormat.defaultTextFormat.copyTo(_bitmapText.textFormat);
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
			if (axisName != null)
			{
				setupBitmapText();
				_bitmapText.text = axisName;
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
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			var bounds:IBounds2D = getReusableBounds();
			axisLineDataBounds.copyTo(bounds);
			return bounds;
		}
		
		private function initPrivateAxisLineBoundsVariables(dataBounds:IBounds2D, screenBounds:IBounds2D):void
		{
			// store data and screen coordinates of axis line into private Bounds2D variables
			axisLineDataBounds.copyTo(_axisLineDataBounds);
			_axisLineScreenBounds.copyFrom(_axisLineDataBounds);
			dataBounds.projectCoordsTo(_axisLineScreenBounds, screenBounds);
		}

		private const _axisLineDataBounds:Bounds2D = new Bounds2D();
		private const _axisLineScreenBounds:Bounds2D = new Bounds2D();
		private const tempPoint:Point = new Point();
		private const tempPoint2:Point = new Point();

		public function getLabel(tickValue:Number):String
		{
			var minValue:Number = tickMinValue.value;
			var maxValue:Number = tickMaxValue.value;
			if (isNaN(minValue))
				minValue = axisLineMinValue.value;
			if (isNaN(maxValue))
				maxValue = axisLineMaxValue.value;
			
			var result:String = null;
			// attempt to use label function
			var labelFunctionResult:String = _labelFunction == null ? null : _labelFunction(tickValue);
			if (_labelFunction != null && labelFunctionResult != null)
			{
				result = labelFunctionResult;
			}
			else if (tickValue == minValue || tickValue == maxValue)
			{
				if (tickValue == int(tickValue))
					_numberFormatter.precision = -1;
				else
					_numberFormatter.precision = 2;
				
				result = _numberFormatter.format(tickValue);
			}
			else
			{
				result = labelNumberFormatter.format(tickValue);
			}
			
			try
			{
				if (labelFunction.value)
					result = labelFunction.apply(null, [tickValue, result]);
			}
			catch (e:Error)
			{
				result = '';
			}
			
			return result;
		}
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