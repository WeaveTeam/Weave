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

package weave.visualization.layers
{
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.controls.ToolTip;
	import mx.core.Application;
	import mx.core.IToolTip;
	import mx.managers.ToolTipManager;
	
	import weave.Weave;
	import weave.WeaveProperties;
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IKeySet;
	import weave.api.getCallbackCollection;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.IPlotter;
	import weave.compiler.StandardLib;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.core.SessionManager;
	import weave.core.StageUtils;
	import weave.core.weave_internal;
	import weave.primitives.Bounds2D;
	import weave.ui.DraggablePanel;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.utils.CustomCursorManager;
	import weave.utils.SpatialIndex;
	import weave.visualization.plotters.ProbeLinePlotter;
	import weave.visualization.plotters.SimpleAxisPlotter;

	use namespace weave_internal;
	
	/**
	 * This is a container for a list of PlotLayers
	 * 
	 * @author adufilie
	 */
	public class SimpleInteractiveVisualization extends InteractiveVisualization
	{
		public function SimpleInteractiveVisualization()
		{
			super();
			linkSessionState(Weave.properties.axisFontSize, axisFontSize);
			linkSessionState(Weave.properties.axisFontFamily, axisFontFamily);
			linkSessionState(Weave.properties.axisFontUnderline, axisFontUnderline);
			linkSessionState(Weave.properties.axisFontItalic, axisFontItalic);
			linkSessionState(Weave.properties.axisFontBold, axisFontBold);
			linkSessionState(Weave.properties.axisFontColor, axisFontColor);
		}

		public static const PROBE_LINE_LAYER_NAME:String = "probeLine";
		public static const X_AXIS_LAYER_NAME:String = "xAxis";
		public static const Y_AXIS_LAYER_NAME:String = "yAxis";
		public static const PLOT_LAYER_NAME:String = "plot";
		
		private var _probeLineLayer:PlotLayer ;
		private var _plotLayer:SelectablePlotLayer;
		private var _xAxisLayer:AxisLayer;
		private var _yAxisLayer:AxisLayer;

		public function getProbeLineLayer():PlotLayer { return _probeLineLayer; }
		public function getPlotLayer():SelectablePlotLayer { return _plotLayer; }
		public function getXAxisLayer():AxisLayer { return _xAxisLayer; }
		public function getYAxisLayer():AxisLayer { return _yAxisLayer; }
		public function getDefaultPlotter():IPlotter { return _plotLayer ? _plotLayer.getDynamicPlotter().internalObject as IPlotter : null; }
		
		public const enableAutoZoomXToNiceNumbers:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), updateZoom);
		public const enableAutoZoomYToNiceNumbers:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), updateZoom);
		
		public const axisFontFamily:LinkableString = registerLinkableChild(this, new LinkableString(WeaveProperties.DEFAULT_FONT_FAMILY));
		public const axisFontBold:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const axisFontItalic:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const axisFontUnderline:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const axisFontSize:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const axisFontColor:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		public const gridLineThickness:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const gridLineColor:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const gridLineAlpha:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		public const axesThickness:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const axesColor:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const axesAlpha:LinkableNumber = newLinkableChild(this, LinkableNumber);
		
		[Inspectable] public function set plotterClass(classDef:Class):void
		{
			if (classDef && !_plotLayer)
			{
				_plotLayer = layers.requestObject(PLOT_LAYER_NAME, SelectablePlotLayer, true);
				_plotLayer.getDynamicPlotter().requestLocalObject(classDef, true);
				layers.addImmediateCallback(this, putAxesOnBottom, null, true);
			}
		}
		
		public function linkToAxisProperties(axisLayer:AxisLayer):void
		{
			if (layers.getName(axisLayer) == null)
				throw new Error("linkToAxisProperties(): given axisLayer is not one of this visualization's layers");
			var p:SimpleAxisPlotter = axisLayer.axisPlotter;
			var list:Array = [
				[axisFontFamily,     p.axisFontFamily],
				[axisFontBold,       p.axisFontBold],
				[axisFontItalic,     p.axisFontItalic],
				[axisFontUnderline,  p.axisFontUnderline],
				[axisFontSize,       p.axisFontSize],
				[axisFontColor,      p.axisFontColor],
				[gridLineThickness,  p.axisGridLineThickness],
				[gridLineColor,      p.axisGridLineColor],
				[gridLineAlpha,      p.axisGridLineAlpha],
				[axesThickness,  p.axesThickness],
				[axesColor,      p.axesColor],
				[axesAlpha,      p.axesAlpha]
			];
			for each (var pair:Array in list)
			{
				var var0:LinkableVariable = pair[0] as LinkableVariable;
				var var1:LinkableVariable = pair[1] as LinkableVariable;
				if (var0.isUndefined())
					linkSessionState(var1, var0);
				else
					linkSessionState(var0, var1);
				(WeaveAPI.SessionManager as SessionManager).removeLinkableChildFromSessionState(p, pair[1]);
			}
			//(WeaveAPI.SessionManager as SessionManager).removeLinkableChildrenFromSessionState(p, p.axisLineDataBounds);
		}

		
		public function get showAxes():Boolean
		{
			return _xAxisLayer != null;
		}
		public function set showAxes(value:Boolean):void
		{
			if (value && !_xAxisLayer)
			{
				// x
				_xAxisLayer = layers.requestObject(X_AXIS_LAYER_NAME, AxisLayer, true);
				_xAxisLayer.axisPlotter.axisLabelRelativeAngle.value = -45;
				_xAxisLayer.axisPlotter.labelVerticalAlign.value = BitmapText.VERTICAL_ALIGN_TOP;
				linkSessionState(marginBottomNumber, _xAxisLayer.axisPlotter.labelWordWrapSize);
				
				linkToAxisProperties(_xAxisLayer);
				
				layers.addImmediateCallback(this, putAxesOnBottom, null, true);
				updateZoom();
				
				// y
				_yAxisLayer = layers.requestObject(Y_AXIS_LAYER_NAME, AxisLayer, true);
				_yAxisLayer.axisPlotter.axisLabelRelativeAngle.value = 45;
				_yAxisLayer.axisPlotter.labelVerticalAlign.value = BitmapText.VERTICAL_ALIGN_BOTTOM;
				linkSessionState(marginLeftNumber, _yAxisLayer.axisPlotter.labelWordWrapSize);
				
				linkToAxisProperties(_yAxisLayer);
				
				layers.addImmediateCallback(this, putAxesOnBottom, null, true);
				updateZoom();
			}
		}
		
		private var tempPoint:Point = new Point(); // reusable temp object
		
		/**
		 * This function orders the layers from top to bottom in this order: 
		 * probe (probe lines), plot, yAxis, xAxis
		 */		
		public function putAxesOnBottom():void
		{
			var names:Array = layers.getNames();
			
			// remove axis layer names so they can be put in front.
			var i:int;
			for each (var name:String in [X_AXIS_LAYER_NAME, Y_AXIS_LAYER_NAME])
			{
				i = names.indexOf(name)
				if (i >= 0)
					names.splice(i, 1);
			}
			
			names.unshift(X_AXIS_LAYER_NAME); // default axes first
			names.unshift(Y_AXIS_LAYER_NAME); // default axes first
			names.push(PROBE_LINE_LAYER_NAME); // probe line layer last
			
			layers.setNameOrder(names);
		}
		
		override protected function updateFullDataBounds():void
		{
			getCallbackCollection(this).delayCallbacks();
			
			super.updateFullDataBounds();
			
			// adjust fullDataBounds based on auto zoom settings
			
			tempBounds.copyFrom(fullDataBounds);
			if(_xAxisLayer && enableAutoZoomXToNiceNumbers.value)
			{
				var xMinMax:Array = StandardLib.getNiceNumbersInRange(fullDataBounds.getXMin(), fullDataBounds.getXMax(), _xAxisLayer.axisPlotter.tickCountRequested.value);
				tempBounds.setXRange(xMinMax.shift(), xMinMax.pop()); // first & last ticks
			}
			if(_yAxisLayer && enableAutoZoomYToNiceNumbers.value)
			{
				var yMinMax:Array = StandardLib.getNiceNumbersInRange(fullDataBounds.getYMin(), fullDataBounds.getYMax(), _yAxisLayer.axisPlotter.tickCountRequested.value);
				tempBounds.setYRange(yMinMax.shift(), yMinMax.pop()); // first & last ticks
			}
			if ((_xAxisLayer || _yAxisLayer) && enableAutoZoomToExtent.value)
			{
				// if axes are enabled and dataBounds is undefined, set dataBounds to default size
				// if bounds is empty, make it not empty
				if (tempBounds.isEmpty())
				{
					if (tempBounds.getWidth() == 0)
						tempBounds.setWidth(1);
					if (tempBounds.getWidth() == 0)
						tempBounds.setXRange(0, 1);
					if (tempBounds.getHeight() == 0)
						tempBounds.setHeight(1);
					if (tempBounds.getHeight() == 0)
						tempBounds.setYRange(0, 1);
				}
			}
			if (!fullDataBounds.equals(tempBounds))
			{
				fullDataBounds.copyFrom(tempBounds);
				getCallbackCollection(this).triggerCallbacks();
			}
			
			getCallbackCollection(this).resumeCallbacks();
		}

		override protected function updateZoom():void
		{
			getCallbackCollection(this).delayCallbacks();
			getCallbackCollection(zoomBounds).delayCallbacks();
			
			super.updateZoom();
			
			// when the data bounds change, we need to update the min,max values for axes
			if (_xAxisLayer)
			{
				getCallbackCollection(_xAxisLayer).delayCallbacks(); // avoid recursive updateZoom() call until done setting session state
				zoomBounds.getDataBounds(tempBounds);
				tempBounds.yMax = tempBounds.yMin;
				_xAxisLayer.axisPlotter.axisLineDataBounds.copyFrom(tempBounds);
				_xAxisLayer.axisPlotter.axisLineMinValue.value = tempBounds.xMin;
				_xAxisLayer.axisPlotter.axisLineMaxValue.value = tempBounds.xMax;
				getCallbackCollection(_xAxisLayer).resumeCallbacks();
			}
			if (_yAxisLayer)
			{
				getCallbackCollection(_yAxisLayer).delayCallbacks(); // avoid recursive updateZoom() call until done setting session state
				zoomBounds.getDataBounds(tempBounds);
				tempBounds.xMax = tempBounds.xMin;
				_yAxisLayer.axisPlotter.axisLineDataBounds.copyFrom(tempBounds);
				_yAxisLayer.axisPlotter.axisLineMinValue.value = tempBounds.yMin;
				_yAxisLayer.axisPlotter.axisLineMaxValue.value = tempBounds.yMax;
				getCallbackCollection(_yAxisLayer).resumeCallbacks();
			}

			getCallbackCollection(zoomBounds).resumeCallbacks();
			getCallbackCollection(this).resumeCallbacks();
		}
		
		override protected function handleRollOut(event:MouseEvent):void
		{
			super.handleRollOut(event);
			
			if (_axisToolTip)
				ToolTipManager.destroyToolTip(_axisToolTip);
			_axisToolTip = null;
		}
		
		override protected function handleMouseClick(event:MouseEvent):void
		{
			super.handleMouseClick(event);
			
			if (mouseIsRolledOver)
			{
				var theMargin:LinkableString = getMarginAndSetQueryBounds(event.localX, event.localY, false);
				var index:int = [marginTop, marginBottom, marginLeft, marginRight].indexOf(theMargin);
				if (index >= 0)
				{
					var ccs:Array = [topMarginClickCallbacks, bottomMarginClickCallbacks, leftMarginClickCallbacks, rightMarginClickCallbacks];
					var cc:ICallbackCollection = getCallbackCollection(ccs[index]);
					cc.triggerCallbacks();
				}
			}
		}
		
		
		/**
		 * This function checks which margin the mouse is over and sets queryBounds to be the bounds of the margin.
		 * @param x X mouse coordinate.
		 * @param y Y mouse coordinate.
		 * @param outerHalf If true, only check the outer half of the margins.
		 * @return marginTop, marginBottom, marginLeft, or marginRight 
		 */		
		private function getMarginAndSetQueryBounds(x:Number, y:Number, outerHalf:Boolean):LinkableString
		{
			var sb:IBounds2D = tempScreenBounds;
			var qb:IBounds2D = queryBounds;
			zoomBounds.getScreenBounds(sb);
			sb.makeSizePositive();
			
			// TOP MARGIN
			qb.copyFrom(sb);
			qb.setYMax(0);
			if (outerHalf)
				qb.setYMin(qb.getYCenter());
			if (qb.contains(x, y))
				return marginTop;

			// BOTTOM MARGIN
			qb.copyFrom(sb);
			qb.setYMin(height);
			if (outerHalf)
				qb.setYMax(qb.getYCenter());
			if (qb.contains(x, y))
				return marginBottom;

			// LEFT MARGIN
			qb.copyFrom(sb);
			qb.setXMax(0);
			if (outerHalf)
				qb.setXMin(qb.getXCenter());
			if (qb.contains(x, y))
				return marginLeft;

			// RIGHT MARGIN
			qb.copyFrom(sb);
			qb.setXMin(width);
			if (outerHalf)
				qb.setXMax(qb.getXCenter());
			if (qb.contains(x, y))
				return marginRight;
			
			return null;
		}
		
		public var topMarginToolTip:String;
		public var bottomMarginToolTip:String;
		public var leftMarginToolTip:String;
		public var rightMarginToolTip:String;
		
		public var topMarginColumn:IAttributeColumn;
		public var bottomMarginColumn:IAttributeColumn;
		public var leftMarginColumn:IAttributeColumn;
		public var rightMarginColumn:IAttributeColumn;
		
		private var _axisToolTip:IToolTip = null;
		override protected function handleMouseMove():void
		{
			super.handleMouseMove();
			
			
			if (mouseIsRolledOver)
			{
				if (_axisToolTip)
					ToolTipManager.destroyToolTip(_axisToolTip);
				_axisToolTip = null;

				
				if (!StageUtils.mouseEvent.buttonDown)
				{
					var theMargin:LinkableString = getMarginAndSetQueryBounds(mouseX, mouseY, true);
					var index:int = [marginTop, marginBottom, marginLeft, marginRight].indexOf(theMargin);
					var axisColumn:IAttributeColumn = null;
					var toolTip:String
					if (index >= 0)
					{
						var columns:Array = [topMarginColumn, bottomMarginColumn, leftMarginColumn, rightMarginColumn];
						var toolTips:Array = [topMarginToolTip, bottomMarginToolTip, leftMarginToolTip, rightMarginToolTip];
						axisColumn = columns[index];
						toolTip = toolTips[index];
						if (!axisColumn)
							theMargin = null;
					}
					
					var stageWidth:int  = stage.stageWidth;
					var stageHeight:int = stage.stageHeight ; //stage.height returns incorrect values
					
					if (theMargin && Weave.properties.enableToolControls.value)
						CustomCursorManager.showCursor(CustomCursorManager.LINK_CURSOR);
					// if we should be creating a tooltip
					if (axisColumn)
					{
						if (!toolTip)
						{
							toolTip = ColumnUtils.getTitle(axisColumn);
							toolTip += "\n Key type: "   + ColumnUtils.getKeyType(axisColumn);
							toolTip += "\n # of records: " + WeaveAPI.StatisticsCache.getCount(axisColumn);
							toolTip += "\n Data source: " + ColumnUtils.getDataSource(axisColumn);
							if (Weave.properties.enableToolControls.value)
								toolTip += "\n Click to select a different attribute.";
						}
						
						// create the actual tooltip
						// queryBounds was set above in getMarginAndSetQueryBounds().
						var ttPoint:Point = localToGlobal( new Point(queryBounds.getXCenter(), queryBounds.getYCenter()) );
						_axisToolTip = ToolTipManager.createToolTip(toolTip, ttPoint.x, ttPoint.y);
						
						// constrain the tooltip to fall within the bounds of the application											
						_axisToolTip.x = Math.max( 0, Math.min(_axisToolTip.x, (stageWidth  - _axisToolTip.width) ) );
						_axisToolTip.y = Math.max( 0, Math.min(_axisToolTip.y, (stageHeight - _axisToolTip.height) ) );
					}
				}
			}
		}
		
		/**
		 * a ProbeLinePlotter instance for the probe line layer 
		 */		
		private var _probePlotter:ProbeLinePlotter = null ;
		
		/**
		 * This function should be called by a tool to initialize a probe line layer and its ProbeLinePlotter.
		 * To disable probe lines, call this function with both parameters set to false.
		 * @param xToolTipEnabled set to true if xAxis needs a probe line and tooltip
		 * @param yToolTipEnabled set to true if yAxis needs a probe line and tooltip
		 * @param xLabelFunction optional function to convert xAxis number values to string
		 * @param yLabelFunction optional function to convert yAxis number values to string
		 */	
		public function enableProbeLine(xToolTipEnabled:Boolean, yToolTipEnabled:Boolean):void
		{
			if (!xToolTipEnabled && !yToolTipEnabled)
			{
				getCallbackCollection(_plotLayer.probeFilter).removeCallback(updateProbeLines);
				return;
			}
			if (!_probeLineLayer)
			{
				_probeLineLayer = layers.requestObject(PROBE_LINE_LAYER_NAME, PlotLayer, true);
				_probePlotter = _probeLineLayer.getDynamicPlotter().requestLocalObject(ProbeLinePlotter, true);
			}
			getCallbackCollection(_plotLayer.probeFilter).addImmediateCallback(this, updateProbeLines, [xToolTipEnabled, yToolTipEnabled], false);
		}
		
		/**
		 * Draws the probe lines using _probePlotter and the corresponding axes tooltips
		 * @param xToolTipEnabled set to true if xAxis needs a probe line and tooltip
		 * @param yToolTipEnabled set to true if yAxis needs a probe line and tooltip
		 * @param labelFunction optional function to convert number values to string 
		 * @param labelFunctionX optional function to convert xAxis number values to string 
		 * 
		 */	
		private function updateProbeLines(xToolTipEnabled:Boolean, yToolTipEnabled:Boolean):void
		{
			destroyProbeLineTooltips();
			if (!Weave.properties.enableProbeLines.value)
				return;
			var keySet:IKeySet = _plotLayer.probeFilter.internalObject as IKeySet;
			if (keySet == null)
			{
				reportError('keySet is null');
				return;
			}
			var recordKeys:Array = keySet.keys;
			
			if (recordKeys.length == 0 || !this.mouseIsRolledOver)
			{
				_probePlotter.clearCoordinates();
				return;
			}
			var xPlot:Number;
			var yPlot:Number;
			var x_yAxis:Number;
			var y_yAxis:Number;
			var x_xAxis:Number;
			var y_xAxis:Number;
			var bounds:IBounds2D = (_plotLayer.spatialIndex as SpatialIndex).getBoundsFromKey(recordKeys[0])[0];
			
			// if there is a visualization with one set of data and the user drag selects over to it, the 
			// spatial index will return an empty array for the key, which means bounds will be null. 
			if (bounds == null) 
				return; 
			
			var yExists:Boolean = isFinite(bounds.getYMin());
			var xExists:Boolean = isFinite(bounds.getXMin());
			
			if( yToolTipEnabled && !xToolTipEnabled && xExists && yExists) // bar charts, histograms
			{
				x_yAxis = _xAxisLayer.axisPlotter.axisLineMinValue.value;
				y_yAxis = bounds.getYMax();
							
				xPlot = bounds.getXCenter();
				yPlot = bounds.getYMax();
				
				 showProbeTooltips(y_yAxis, bounds, _yAxisLayer.axisPlotter.getLabel);
				_probePlotter.setCoordinates(x_yAxis, y_yAxis, xPlot, yPlot, x_xAxis, y_xAxis, yToolTipEnabled, xToolTipEnabled);
				
			}
			else if (yToolTipEnabled && xToolTipEnabled) //scatterplot
			{
				var xAxisMin:Number = _xAxisLayer.axisPlotter.axisLineMinValue.value;
				var yAxisMin:Number = _yAxisLayer.axisPlotter.axisLineMinValue.value;
				
				var xAxisMax:Number = _xAxisLayer.axisPlotter.axisLineMaxValue.value;
				var yAxisMax:Number = _yAxisLayer.axisPlotter.axisLineMaxValue.value;
				
				if (yExists || xExists)
				{
					x_yAxis = xAxisMin;
					y_yAxis = bounds.getYMax();
					
					xPlot = (xExists) ? bounds.getXCenter() : xAxisMax;
					yPlot = (yExists) ? bounds.getYMax() : yAxisMax;
					
					x_xAxis = bounds.getXCenter();
					y_xAxis = yAxisMin;

					if (yExists)
						showProbeTooltips(y_yAxis, bounds, _yAxisLayer.axisPlotter.getLabel);
					if (xExists)
						showProbeTooltips(x_xAxis, bounds, _xAxisLayer.axisPlotter.getLabel, true);
					_probePlotter.setCoordinates(x_yAxis, y_yAxis, xPlot, yPlot, x_xAxis, y_xAxis, yExists, xExists);
				}
			}
			else if (!yToolTipEnabled && xToolTipEnabled) // special case for horizontal bar chart
			{
				xPlot = bounds.getXMax();
				yPlot = bounds.getYCenter();
				
				x_xAxis = xPlot;
				y_xAxis = _yAxisLayer.axisPlotter.axisLineMinValue.value;
				
				showProbeTooltips(xPlot, bounds, _xAxisLayer.axisPlotter.getLabel, false, true);
				
				_probePlotter.setCoordinates(x_yAxis, y_yAxis, xPlot, yPlot, x_xAxis, y_xAxis, false, true);
			}
		}
		
		/**
		 * 
		 * @param displayValue value to display in the tooltip
		 * @param bounds data bounds from a record key
		 * @param labelFunction function to generate strings from the displayValue
		 * @param xAxis flag to specify whether this is an xAxis tooltip
		 * @param useXMax flag to specify whether the toolTip should appear at the xMax of the record's bounds (as opposed to the xCenter, which positions the toolTip at the middle)
		 */
		public function showProbeTooltips(displayValue:Number, bounds:IBounds2D, labelFunction:Function, xAxis:Boolean = false, useXMax:Boolean = false):void
		{
			var yPoint:Point = new Point();
			var text:String = "";
			if (labelFunction != null)
				text = labelFunction(displayValue);
			
			if (!text)
				text = StandardLib.formatNumber(displayValue);
			
			if (xAxis || useXMax)
			{
				yPoint.x = (xAxis) ? bounds.getXCenter() : bounds.getXMax();
				yPoint.y = _yAxisLayer.axisPlotter.axisLineMinValue.value;					
			}
			else
			{
				yPoint.x = _xAxisLayer.axisPlotter.axisLineMinValue.value;
				yPoint.y = bounds.getYMax() ;
			}
			zoomBounds.getDataBounds(tempDataBounds);
			zoomBounds.getScreenBounds(tempScreenBounds);
			tempDataBounds.projectPointTo(yPoint, tempScreenBounds);
			yPoint = localToGlobal(yPoint);
			
			if (xAxis || useXMax)
			{
				xAxisTooltip = ToolTipManager.createToolTip(text, yPoint.x, yPoint.y);
				xAxisTooltip.move(xAxisTooltip.x - (xAxisTooltip.width / 2), xAxisTooltip.y);
				xAxisTooltipPtr = xAxisTooltip;
			}
			else
			{
				yAxisTooltip = ToolTipManager.createToolTip(text, yPoint.x, yPoint.y);
				yAxisTooltip.move(yAxisTooltip.x - yAxisTooltip.width, yAxisTooltip.y - (yAxisTooltip.height / 2));
				yAxisTooltipPtr = yAxisTooltip
			}
			constrainToolTipsToStage(xAxisTooltip, yAxisTooltip);
			if (!yAxisTooltip)
				yAxisTooltipPtr = null;
			if (!xAxisTooltip)
				xAxisTooltipPtr = null;
			setProbeToolTipAppearance();
			
		}
		
		/**
		 * Sets the style of the probe line axes tooltips to match the color and alpha of the primary probe tooltip 
		 */		
		private function setProbeToolTipAppearance():void
		{
			for each (var tooltip:IToolTip in [xAxisTooltip, yAxisTooltip])
				if ( tooltip != null )
				{
					(tooltip as ToolTip).setStyle("backgroundAlpha", Weave.properties.probeToolTipBackgroundAlpha.value);
					if (isFinite(Weave.properties.probeToolTipBackgroundColor.value))
						(tooltip as ToolTip).setStyle("backgroundColor", Weave.properties.probeToolTipBackgroundColor.value);
				}
		}
		
		/**
		 * This function corrects the parameter toolTip positions if they go offstage
		 * @param toolTip An object that implements IToolTip
		 * @param moreToolTips more objects that implement IToolTip
		 */		
		public function constrainToolTipsToStage(tooltip:IToolTip, ...moreToolTips):void
		{
			var xMin:Number = 0;
			
			moreToolTips.unshift(tooltip);
			for each (tooltip in moreToolTips)
			{
				if (tooltip != null)
				{
					if (tooltip.x < xMin)
						tooltip.move(tooltip.x+Math.abs(xMin-tooltip.x), tooltip.y);
					var xMax:Number = stage.stageWidth - (tooltip.width/2);
					var xMaxTooltip:Number = tooltip.x+(tooltip.width/2);
					if (xMaxTooltip > xMax)
					{
						tooltip.move(xMax-(tooltip.width/2),tooltip.y);
					}
				}
			}
						
		}
		
		/**
		 * This function destroys the probe line axes tooltips. 
		 * Also sets the public static variables xAxisTooltipPtr, yAxisTooltipPtr to null
		 */		
		public function destroyProbeLineTooltips():void
		{
			if (yAxisTooltip != null)
			{
				ToolTipManager.destroyToolTip(yAxisTooltip);
				yAxisTooltip = null;	
				yAxisTooltipPtr = null;	
			}
			if (xAxisTooltip != null)
			{
				ToolTipManager.destroyToolTip(xAxisTooltip);
				xAxisTooltip = null;
				xAxisTooltipPtr = null;
			}
		}
		
		private var yAxisTooltip:IToolTip = null;
		private var xAxisTooltip:IToolTip = null;
		
		/**
		 * Static pointer to the yAxisTooltip 
		 */		
		public static var yAxisTooltipPtr:IToolTip = null ;
		/**
		 * Static pointer to the xAxisTooltip 
		 */		
		public static var xAxisTooltipPtr:IToolTip = null ;
		
		public const bottomMarginClickCallbacks:ICallbackCollection = newDisposableChild(this, CallbackCollection);
		public const leftMarginClickCallbacks:ICallbackCollection = newDisposableChild(this, CallbackCollection);
		public const topMarginClickCallbacks:ICallbackCollection = newDisposableChild(this, CallbackCollection);
		public const rightMarginClickCallbacks:ICallbackCollection = newDisposableChild(this, CallbackCollection);
		
		private const tempBounds:Bounds2D = new Bounds2D();
	}
}
