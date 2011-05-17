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
	import weave.api.ui.IPlotter;
	import weave.compiler.MathLib;
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
			init();
		}
		private function init():void
		{
			linkSessionState(Weave.properties.axisFontSize, axisFontSize);
			linkSessionState(Weave.properties.axisFontFamily, axisFontFamily);
			linkSessionState(Weave.properties.axisFontUnderline, axisFontUnderline);
			linkSessionState(Weave.properties.axisFontItalic, axisFontItalic);
			linkSessionState(Weave.properties.axisFontBold, axisFontBold);
			linkSessionState(Weave.properties.axisFontColor, axisFontColor);
			
			// when the data bounds change, we need to update the axes
			getCallbackCollection(dataBounds).addImmediateCallback(this, handleDataBoundsChange);
			enableAutoZoomToExtent.addImmediateCallback(this, handleDataBoundsChange);
		}

		private const PROBE_LINE_LAYER_NAME:String = "probeLine";
		private const xAxisLayerName:String = "xAxis";
		private const yAxisLayerName:String = "yAxis";
		private const plotLayerName:String = "plot";
		
		private var _probeLineLayer:PlotLayer ;
		private var _plotLayer:SelectablePlotLayer;
		private var _xAxisLayer:AxisLayer;
		private var _yAxisLayer:AxisLayer;

		public function getProbeLineLayer():PlotLayer { return _probeLineLayer; }
		public function getPlotLayer():SelectablePlotLayer { return _plotLayer; }
		public function getXAxisLayer():AxisLayer { return _xAxisLayer; }
		public function getYAxisLayer():AxisLayer { return _yAxisLayer; }
		public function getDefaultPlotter():IPlotter { return _plotLayer ? _plotLayer.getDynamicPlotter().internalObject as IPlotter : null; }
		
		public const enableAutoZoomXToNiceNumbers:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), handleAxisModeChange);
		public const enableAutoZoomYToNiceNumbers:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), handleAxisModeChange);
		
		public const axisFontFamily:LinkableString = registerLinkableChild(this, new LinkableString(WeaveProperties.DEFAULT_FONT_FAMILY, WeaveProperties.verifyFontFamily));
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
				_plotLayer = layers.requestObject(plotLayerName, SelectablePlotLayer, true);
				_plotLayer.getDynamicPlotter().requestLocalObject(classDef, true);
				layers.addImmediateCallback(this, putAxesOnBottom, null, true);
			}
		}
		
		public function linkToAxisProperties(axisLayer:AxisLayer):void
		{
			if (layers.getName(axisLayer) == null)
				throw new Error("linkToAxisPlotterProperties(): given axisLayer is not owned by this visualization's layers property.");
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
				(WeaveAPI.SessionManager as SessionManager).removeLinkableChildrenFromSessionState(p, pair[1]);
			}
			//(WeaveAPI.SessionManager as SessionManager).removeLinkableChildrenFromSessionState(p, p.axisLineDataBounds);
		}

		
		public function set xAxisEnabled(value:Boolean):void
		{
			if (value && !_xAxisLayer)
			{
				_xAxisLayer = layers.requestObject(xAxisLayerName, AxisLayer, true);
				_xAxisLayer.axisPlotter.axisLabelRelativeAngle.value = -45;
				_xAxisLayer.axisPlotter.labelVerticalAlign.value = BitmapText.VERTICAL_ALIGN_TOP;
				
				linkToAxisProperties(_xAxisLayer);
				
				layers.addImmediateCallback(this, putAxesOnBottom, null, true);
				handleAxisModeChange();
			}
		}
		public function set yAxisEnabled(value:Boolean):void
		{
			if (value && !_yAxisLayer)
			{
				_yAxisLayer = layers.requestObject(yAxisLayerName, AxisLayer, true);
				_yAxisLayer.axisPlotter.axisLabelRelativeAngle.value = 45;
				_yAxisLayer.axisPlotter.labelVerticalAlign.value = BitmapText.VERTICAL_ALIGN_BOTTOM;
				
				linkToAxisProperties(_yAxisLayer);
				
				layers.addImmediateCallback(this, putAxesOnBottom, null, true);
				handleAxisModeChange();
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
			var xAxisIndex:int = names.indexOf(xAxisLayerName);
			var yAxisIndex:int = names.indexOf(yAxisLayerName);
			var probeIndex:int = names.indexOf(PROBE_LINE_LAYER_NAME);
			if (xAxisIndex >= 0)
				names.splice(xAxisIndex, 1);
			if (yAxisIndex >= 0)
				names.splice(yAxisIndex, 1);
			if( probeIndex >= 0)
				names.splice(probeIndex, 1);
			names.unshift(xAxisLayerName); // default axes first
			names.unshift(yAxisLayerName); // default axes first
			names.push(plotLayerName); // plot before last
			names.push(PROBE_LINE_LAYER_NAME); // probe layer last
			
			layers.setNameOrder(names);
		}
		
		private function handleAxisModeChange():void
		{
			updateFullDataBounds();
			handleDataBoundsChange();
			handleZoomSettingsChange();
		}
		
		override protected function updateFullDataBounds():void
		{
			super.updateFullDataBounds();
			
			var niceMinMax:Array;
			if(_xAxisLayer && enableAutoZoomXToNiceNumbers.value)
			{
				niceMinMax = MathLib.getNiceNumbersInRange(fullDataBounds.getXMin(), fullDataBounds.getXMax(), _xAxisLayer.axisPlotter.tickCountRequested.value);
				
				fullDataBounds.setXRange(niceMinMax.shift(), niceMinMax.pop()); // first & last ticks
			}
			if(_yAxisLayer && enableAutoZoomYToNiceNumbers.value)
			{
				niceMinMax = MathLib.getNiceNumbersInRange(fullDataBounds.getYMin(), fullDataBounds.getYMax(), _yAxisLayer.axisPlotter.tickCountRequested.value);
				
				fullDataBounds.setYRange(niceMinMax.shift(), niceMinMax.pop()); // first & last ticks
			}
		}
		
		private function handleDataBoundsChange():void
		{
			if ((_xAxisLayer || _yAxisLayer) && enableAutoZoomToExtent.value)
			{
				// if axes are enabled and dataBounds is undefined, set dataBounds to default size
				dataBounds.copyTo(tempBounds);
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
					
					dataBounds.copyFrom(tempBounds);
					// this function will be called again after updating data bounds, so we can just return now
					return;
				}
			}
			// update min,max values for axes
			if (_xAxisLayer)
			{
				dataBounds.copyTo(tempBounds);
				tempBounds.yMax = tempBounds.yMin;
				_xAxisLayer.axisPlotter.axisLineDataBounds.copyFrom(tempBounds);
				_xAxisLayer.axisPlotter.axisLineMinValue.value = tempBounds.xMin;
				_xAxisLayer.axisPlotter.axisLineMaxValue.value = tempBounds.xMax;
			}
			if (_yAxisLayer)
			{
				dataBounds.copyTo(tempBounds);
				tempBounds.xMax = tempBounds.xMin;
				_yAxisLayer.axisPlotter.axisLineDataBounds.copyFrom(tempBounds);
				_yAxisLayer.axisPlotter.axisLineMinValue.value = tempBounds.yMin;
				_yAxisLayer.axisPlotter.axisLineMaxValue.value = tempBounds.yMax;
			}
		}
		
		override protected function handleRollOut(event:MouseEvent):void
		{
			super.handleRollOut(event);
			
			if(_axisToolTip)
				ToolTipManager.destroyToolTip(_axisToolTip);
			_axisToolTip = null;
		}
		
		override protected function handleMouseClick(event:MouseEvent):void
		{
			super.handleMouseClick(event);
			
			if (mouseIsRolledOver)
			{
				getScreenBounds(tempScreenBounds);
				
				// handle clicking above the visualization
				queryBounds.copyFrom(tempScreenBounds);
				queryBounds.setYRange(0, tempScreenBounds.getYNumericMin());
				if (queryBounds.contains(event.localX, event.localY))
					topMarginClickCallbacks.triggerCallbacks();

				// handle clicking below the visualization
				queryBounds.copyFrom(tempScreenBounds);
				queryBounds.setYRange(tempScreenBounds.getYNumericMax(), height);
				//queryBounds.yMin = queryBounds.yMax - (_xAxisLayer ? _xAxisLayer.axisPlotter.getLabelHeight() : 0);
				if (queryBounds.contains(event.localX, event.localY))
					bottomMarginClickCallbacks.triggerCallbacks();

				// handle clicking to the left of the visualization
				queryBounds.copyFrom(tempScreenBounds);
				queryBounds.setXRange(0, tempScreenBounds.getXNumericMin());
				//queryBounds.xMax =  queryBounds.xMax + (_yAxisLayer ? _yAxisLayer.axisPlotter.getLabelHeight() : 0);
				if (queryBounds.contains(event.localX, event.localY))
					leftMarginClickCallbacks.triggerCallbacks();

				// handle clicking to the right of the visualization
				queryBounds.copyFrom(tempScreenBounds);
				queryBounds.setXRange(tempScreenBounds.getXNumericMax(), width);
				if (queryBounds.contains(event.localX, event.localY))
					rightMarginClickCallbacks.triggerCallbacks();
			}
				
		}
		
		//private var _marginCallbackOffset:int = 10;
		
		public var enableXAxisProbing:Boolean = false;
		public var enableYAxisProbing:Boolean = false;
		
		private var _xAxisColumn:IAttributeColumn = null;
		public function setXAxisColumn(column:IAttributeColumn):void
		{
			_xAxisColumn = column;
		}
		private var _yAxisColumn:IAttributeColumn = null;
		public function setYAxisColumn(column:IAttributeColumn):void
		{
			_yAxisColumn = column;
		}
		
		
		
		
		private var _axisToolTip:IToolTip = null;
		override protected function handleMouseMove():void
		{
			super.handleMouseMove();
			
			
			if (mouseIsRolledOver)
			{
				if(_axisToolTip)
					ToolTipManager.destroyToolTip(_axisToolTip);
				_axisToolTip = null;

				
				if (!StageUtils.mouseEvent.buttonDown)
				{
					
					getScreenBounds(tempScreenBounds);
				
					var ttPoint:Point;
					
					var stageWidth:int  = stage.width;
					var stageHeight:int = stage.height;
					var createXTooltip:Boolean = false;
					var createYTooltip:Boolean = false;
					
					if(enableXAxisProbing)
					{
						// handle probing below the visualization
						queryBounds.copyFrom(tempScreenBounds);
						queryBounds.setYRange((tempScreenBounds.getYNumericMax() + height) / 2, height);
						//queryBounds.yMin = queryBounds.yMax - _xAxisLayer.axisPlotter.getLabelHeight();
						
						if(queryBounds.contains(StageUtils.mouseEvent.localX, StageUtils.mouseEvent.localY))
						{
							ttPoint = localToGlobal( new Point(queryBounds.getXCoverage()/2, queryBounds.getYMax()) ); 
											
							createXTooltip = true;
							
							//hideMouseCursors();
						}
					}
	
					if(enableYAxisProbing)
					{
						// handle probing on the left of the visualization
						queryBounds.copyFrom(tempScreenBounds);
						queryBounds.setXRange(0, (tempScreenBounds.getXNumericMin() + 0) / 2);
						//queryBounds.xMin =  queryBounds.xMax + _yAxisLayer.axisPlotter.getLabelHeight();
						
						if(queryBounds.contains(StageUtils.mouseEvent.localX,StageUtils.mouseEvent.localY))
						{
							ttPoint = localToGlobal( new Point(queryBounds.getXMax(), queryBounds.getYCoverage()/2) ); 
	
							createYTooltip = true;
							
							//hideMouseCursors();
						}						
					}
					
					
					// if we should be creating a tooltip
					if(createXTooltip || createYTooltip)
					{	
						CustomCursorManager.showCursor(CustomCursorManager.LINK_CURSOR);

						var toolTip:String;
						
						// if we are creating the x tooltip and a column is specified for this axis, then show its keyType and dataSource
						if(createXTooltip && _xAxisColumn)
						{
							// by default, just show that you can click the axis to change attribute
							toolTip = "Click \"" + ColumnUtils.getTitle(_xAxisColumn) + "\" to select a different attribute. ";
							toolTip += "\n Key Type: "   + ColumnUtils.getKeyType(_xAxisColumn);
							toolTip += "\n # of Records: " + WeaveAPI.StatisticsCache.getCount(_xAxisColumn);
							toolTip += "\n Data Source:" + _xAxisColumn.getMetadata(AttributeColumnMetadata.DATA_SOURCE);
						}
						// otherwise show this for the y axis
						else if(createYTooltip && _yAxisColumn)
						{
							toolTip = "Click \"" + ColumnUtils.getTitle(_yAxisColumn) + "\" to select a different attribute. ";
							toolTip += "\n Key Type: "   + ColumnUtils.getKeyType(_yAxisColumn);
							toolTip += "\n # of Records: " + WeaveAPI.StatisticsCache.getCount(_yAxisColumn);
							toolTip += "\n Data Source:" + _yAxisColumn.getMetadata(AttributeColumnMetadata.DATA_SOURCE);
						}
						
						// create the actual tooltip
						_axisToolTip = ToolTipManager.createToolTip(toolTip, ttPoint.x, ttPoint.y);
						
						// constrain the tooltip to fall within the bounds of the application											
						_axisToolTip.x = Math.max( 0, Math.min(_axisToolTip.x, (stageWidth  - _axisToolTip.width) ) );
						_axisToolTip.y = Math.max( 0, Math.min(_axisToolTip.y, (stageHeight - _axisToolTip.height) ) );
					}
				}
			}
		}
		
		/**
		 * indicates whether the bar chart is in horizontal mode 
		 */		
		public var barChartHorizontalMode:Boolean = false;
		
		/**
		 * indicates whether the bar chart is in grouped mode 
		 */		
		public var barChartGroupMode:Boolean = false;
		/**
		 * a ProbeLinePlotter instance for the probe line layer 
		 */		
		private var _probePlotter:ProbeLinePlotter = null ;
		
		/**
		 * This function should be called by a tool to initialize a probe line layer and its ProbeLinePlotter
		 * @param xAxisToPlot set to true if xAxis needs a probe line and tooltip
		 * @param yAxisToPlot set to true if yAxis needs a probe line and tooltip
		 * @param labelFunction optional function to convert number values to string 
		 * @param labelFunctionX optional function to convert xAxis number values to string
		 */	
		public function enableProbeLine(xAxisToPlot:Boolean,yAxisToPlot:Boolean,labelFunction:Function=null,labelFunctionX:Function=null):void
		{
			if( !_probeLineLayer ) {
				_probeLineLayer = layers.requestObject(PROBE_LINE_LAYER_NAME, PlotLayer, true);
				_probePlotter = _probeLineLayer.getDynamicPlotter().requestLocalObject(ProbeLinePlotter, true);
			}
			getCallbackCollection(_plotLayer.probeFilter).addImmediateCallback(this, updateProbeLines,[xAxisToPlot,yAxisToPlot,labelFunction, labelFunctionX]);
		}
		
		/**
		 * Disables probe lines by removing the appropriate function from the list of callbacks
		 */
		public function disableProbelines():void 
		{
			getCallbackCollection(_plotLayer.probeFilter).removeCallback(updateProbeLines);
		}
		
		/**
		 * Draws the probe lines using _probePlotter and the corresponding axes tooltips
		 * @param xAxisToPlot set to true if xAxis needs a probe line and tooltip
		 * @param yAxisToPlot set to true if yAxis needs a probe line and tooltip
		 * @param labelFunction optional function to convert number values to string 
		 * @param labelFunctionX optional function to convert xAxis number values to string 
		 * 
		 */	
		private function updateProbeLines(xAxisToPlot:Boolean, yAxisToPlot:Boolean, labelFunctionY:Function, labelFunctionX:Function):void
		{
			destroyProbeLineTooltips();
			if(!Weave.properties.enableProbeLines.value)
				return;
			var recordKeys:Array = (_plotLayer.probeFilter.internalObject as IKeySet).keys;
			
			if( (recordKeys.length == 0) || ((this.parent as DraggablePanel) != DraggablePanel.activePanel))
			{
				_probePlotter.clearCoordinates();
				return;
			}
			var x_yAxis:Number, y_yAxis:Number, xPlot:Number, yPlot:Number, x_xAxis:Number, y_xAxis:Number;
			var bounds:IBounds2D = (_plotLayer.spatialIndex as SpatialIndex).getBoundsFromKey(recordKeys[0])[0];
			if( yAxisToPlot )
			{
				x_yAxis = _xAxisLayer.axisPlotter.axisLineMinValue.value;
				y_yAxis = bounds.getYMax();
				
				xPlot = bounds.getXCenter();
				yPlot = bounds.getYMax();
				
				if(xAxisToPlot)
				{
					x_xAxis = bounds.getXCenter();
					y_xAxis = _yAxisLayer.axisPlotter.axisLineMinValue.value ;
					showProbeTooltips(x_xAxis, bounds,labelFunctionX,true);
				}
				
				showProbeTooltips(y_yAxis,bounds,labelFunctionY);
				_probePlotter.setCoordinates(x_yAxis,y_yAxis,xPlot,yPlot,x_xAxis,y_xAxis,true, xAxisToPlot );
			} else
			{
				xPlot = bounds.getXMax();
				yPlot = bounds.getYCenter();
				
				x_xAxis = xPlot;
				y_xAxis = _yAxisLayer.axisPlotter.axisLineMinValue.value;
				
				showProbeTooltips(xPlot, bounds, labelFunctionY,false, true);
				
				_probePlotter.setCoordinates(x_yAxis,y_yAxis,xPlot,yPlot,x_xAxis,y_xAxis, false, true);
				
			}
		}
		
		/**
		 * 
		 * @param displayValue value to display in the tooltip
		 * @param bounds data bounds from a record key
		 * @param labelFunction function to generate strings from the displayValue
		 * @param xAxis flag to specify whether this is an xAxis tooltip
		 * @param horizontalMode flag to specify bar chart horizontal mode
		 * 
		 */
		public function showProbeTooltips(displayValue:Number,bounds:IBounds2D,labelFunction:Function,xAxis:Boolean=false, horizontalMode:Boolean=false):void
		{
			var yPoint:Point = new Point();
			var text1:String = "";
			if(labelFunction != null)
				text1=labelFunction(displayValue);
			else text1=displayValue.toString();
			
			if(xAxis)
			{
				yPoint.x = bounds.getXCenter();
				yPoint.y = _yAxisLayer.axisPlotter.axisLineMinValue.value;
			} else if( horizontalMode)
			{
				yPoint.x = bounds.getXMax() ;
				yPoint.y = _yAxisLayer.axisPlotter.axisLineMinValue.value;
			} else if(!xAxis && !horizontalMode)
			{
				yPoint.x = _xAxisLayer.axisPlotter.axisLineMinValue.value;
				yPoint.y = bounds.getYMax() ;
			}
			dataBounds.copyTo(tempDataBounds);
			getScreenBounds(tempScreenBounds);
			tempDataBounds.projectPointTo(yPoint, tempScreenBounds);
			yPoint = localToGlobal(yPoint);
			
			if(!xAxis && !horizontalMode)
			{
				yAxisTooltip = ToolTipManager.createToolTip(text1, yPoint.x, yPoint.y);
				yAxisTooltip.move(yAxisTooltip.x-yAxisTooltip.width, yAxisTooltip.y-(yAxisTooltip.height/2));
				constrainTooltipToStage();
			} else
			{
				xAxisTooltip = ToolTipManager.createToolTip(text1, yPoint.x, yPoint.y);
				xAxisTooltip.move(xAxisTooltip.x-(xAxisTooltip.width/2),xAxisTooltip.y);
				constrainTooltipToStage();
			}
			setProbeToolTipAppearance();
			
		}
		
		/**
		 * Sets the style of the probe line axes tooltips to match the color and alpha of the primary probe tooltip 
		 */		
		private function setProbeToolTipAppearance():void
		{
			for each (var tooltip:IToolTip in [xAxisTooltip, yAxisTooltip])
				if( tooltip != null )
				{
					(tooltip as ToolTip).setStyle("backgroundAlpha", Weave.properties.probeToolTipBackgroundAlpha.value);
					if (isFinite(Weave.properties.probeToolTipBackgroundColor.value))
						(tooltip as ToolTip).setStyle("backgroundColor", Weave.properties.probeToolTipBackgroundColor.value);
				}
		}
		
		/**
		 * This function corrects the probe x and y axes tooltip positions if they go offstage
		 */		
		private function constrainTooltipToStage():void
		{
			var xMin:Number = stage.x;
			
			if( yAxisTooltip != null ) 
			{
				if( yAxisTooltip.x < xMin ) 
					yAxisTooltip.move(yAxisTooltip.x+Math.abs(xMin-yAxisTooltip.x), yAxisTooltip.y );
				yAxisTooltipPtr = yAxisTooltip;
			}
			else yAxisTooltipPtr = null;
			if( xAxisTooltip != null )
			{
				var xMax:Number = stage.width - xAxisTooltip.width;
				var xMaxTooltip:Number = xAxisTooltip.x+xAxisTooltip.width;
				while( xMaxTooltip > stage.width)
				{
					xAxisTooltip.move(--xAxisTooltip.x, xAxisTooltip.y);
					xMaxTooltip = xAxisTooltip.x+xAxisTooltip.width;
				}
				xAxisTooltipPtr = xAxisTooltip;
			}
			else xAxisTooltipPtr = null; 
		}
		
		/**
		 * This function destroys the probe line axes tooltips. 
		 * Also sets the public static variables xAxisTooltipPtr, yAxisTooltipPtr to null
		 */		
		public function destroyProbeLineTooltips():void
		{
			if(yAxisTooltip!=null)
			{
				ToolTipManager.destroyToolTip(yAxisTooltip);
				yAxisTooltip = null;	
				yAxisTooltipPtr = null;	
			}
			if(xAxisTooltip != null)
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
