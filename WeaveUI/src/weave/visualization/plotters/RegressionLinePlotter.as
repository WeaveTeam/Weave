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
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.reportError;
	import weave.core.ErrorManager;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.primitives.Range;
	import weave.services.DelayedAsyncResponder;
	import weave.services.WeaveStatisticsServlet;
	import weave.services.beans.RResult;
	import weave.utils.ColumnUtils;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * RegressionLinePlotter
	 * 
	 * @author kmanohar
	 */
	public class RegressionLinePlotter extends AbstractPlotter
	{
		public function RegressionLinePlotter()
		{
			Weave.properties.rServiceURL.addImmediateCallback(this, resetRService, null, true);
			spatialCallbacks.addImmediateCallback(this, resetRegressionLine );
			spatialCallbacks.addGroupedCallback(this, calculateRRegression );
			setKeySource(xColumn);
			
			// hack to fix old session states
			_filteredKeySet.addImmediateCallback(this, function():void {
				if (_filteredKeySet.keyFilter.globalName == null)
					_filteredKeySet.keyFilter.globalName = Weave.DEFAULT_SUBSET_KEYFILTER;
			});
		}
		
		public const drawLine:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		
		public const xColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const yColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);

		private var rService:WeaveStatisticsServlet = null;
		
		private function resetRService():void
		{
			rService = new WeaveStatisticsServlet(Weave.properties.rServiceURL.value);
		}
		
		private function resetRegressionLine():void
		{
			// clear previous values
			slope = NaN;
			intercept = NaN;
		}
		private function calculateRRegression():void
		{
			//trace( "calculateRegression() " + xColumn.toString() );
			if( drawLine.value )
			{
				var Rstring:String = "fit <- lm(y~x)\n"
					+"intercept <- coefficients(fit)[1]\n"
					+"slope <- coefficients(fit)[2]\n"
					+"rSquared <- summary(fit)$r.squared\n";
				
				var dataXY:Array = ColumnUtils.joinColumns([xColumn, yColumn], Number, false, keySet.keys);
				
				// sends a request to Rserve to calculate the slope and intercept of a regression line fitted to xColumn and yColumn 
				var token:AsyncToken = rService.runScript(["x","y"],[dataXY[1],dataXY[2]],["intercept","slope","rSquared"],Rstring,"",false,false);
				DelayedAsyncResponder.addResponder(token, handleLinearRegressionResult, handleLinearRegressionFault, ++requestID);
			}
		}
		private var requestID:int = 0; // ID of the latest request, used to ignore old results
		
		private function handleLinearRegressionResult(event:ResultEvent, token:Object=null):void
		{
			if (this.requestID != int(token))
			{
				// ignore outdated results
				return;
			}
			
			var Robj:Array = event.result as Array;
			if (Robj == null)
				return;
			
			var RresultArray:Array = new Array();
			
			//collecting Objects of type RResult(Should Match result object from Java side)
			for(var i:int = 0; i<Robj.length; i++)
			{
				var rResult:RResult = new RResult(Robj[i]);
				RresultArray.push(rResult);				
			}
			
			if (RresultArray.length > 1)
			{
				intercept = (Number((RresultArray[0] as RResult).value) != intercept) ? Number((RresultArray[0] as RResult).value) : NaN ;
				slope = Number((RresultArray[1] as RResult).value);
				rSquared = Number((RresultArray[2] as RResult).value);
				//trace( "R" + " " + intercept + " " + slope) ;
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		private function handleLinearRegressionFault(event:FaultEvent, token:Object = null):void
		{
			if (this.requestID != int(token))
			{
				// ignore outdated results
				return;
			}
			
			reportError(event, null, token);
			intercept = NaN;
			slope = NaN;
			getCallbackCollection(this).triggerCallbacks();
		}
		
		public function getSlope():Number { return slope; }
		public function getIntercept():Number { return intercept; }

		private var intercept:Number = NaN;
		private var slope:Number = NaN;
		private var rSquared:Number = NaN;
		private var tempRange:Range = new Range();
		private var tempPoint:Point = new Point();
		private var tempPoint2:Point = new Point();

		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if(drawLine.value)
			{
				var g:Graphics = tempShape.graphics; 
				g.clear();
				
				if(!isNaN(intercept))
				{
					tempPoint.x = dataBounds.getXMin();
					tempPoint2.x = dataBounds.getXMax();
					
					tempPoint.y = (slope*tempPoint.x)+intercept;
					tempPoint2.y = (slope*tempPoint2.x)+intercept;
					
					tempRange.setRange( dataBounds.getYMin(), dataBounds.getYMax() );
					
					// constrain yMin to be within y range and derive xMin from constrained yMin
					tempPoint.x = tempPoint.x + (tempRange.constrain(tempPoint.y) - tempPoint.y) / slope;
					tempPoint.y = tempRange.constrain(tempPoint.y);
					
					// constrain yMax to be within y range and derive xMax from constrained yMax
					tempPoint2.x = tempPoint.x + (tempRange.constrain(tempPoint2.y) - tempPoint.y) / slope;
					tempPoint2.y = tempRange.constrain(tempPoint2.y);
					
					dataBounds.projectPointTo(tempPoint,screenBounds);
					dataBounds.projectPointTo(tempPoint2,screenBounds);
					lineStyle.beginLineStyle(null,g);
					//g.lineStyle(lineThickness.value, lineColor.value,lineAlpha.value,true,LineScaleMode.NONE);
					g.moveTo(tempPoint.x,tempPoint.y);
					g.lineTo(tempPoint2.x,tempPoint2.y);
					
					destination.draw(tempShape);
				}
			}		
		}
		override public function dispose():void
		{
			super.dispose();
			requestID = 0; // forces all results from previous requests to be ignored
		}
	}
}
