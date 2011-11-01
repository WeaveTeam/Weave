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
	
	import weave.api.data.ISimpleGeometry;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotterWithGeometrySelection;
	import weave.core.LinkableNumber;
	import weave.primitives.SimpleGeometry;

	/**
	 * 
	 * @author skolman
	 * @author kmonico
	 */	
	public class CirclePlotter extends AbstractPlotter implements IPlotterWithGeometrySelection
	{
		public function CirclePlotter()
		{
		}
		
		/**
		 * The x position of the circle. 
		 */		
		public const dataX:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		
		/**
		 * The y position of the circle. 
		 */		
		public const dataY:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		
		/**
		 * The radius of the circle. 
		 */		
		public const radius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1));
		
		/**
		 * The color of the circle. 
		 */		
		public const color:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0));
		
		/**
		 * The thickness of the edge of the circle. 
		 */		
		public const thickness:LinkableNumber = registerLinkableChild(this, new LinkableNumber(2));
		
		/**
		 * The number of vertices to use inside the polygon when selecting records. This must be at
		 * least <code>3</code>. <br>
		 * @default 25
		 */		
		public const polygonVertexCount:LinkableNumber = registerLinkableChild(this, new LinkableNumber(25, verifyPolygonVertexCount));
		private function verifyPolygonVertexCount(value:Number):Boolean
		{
			return value >= 3; 
		}

		/**
		 * This function will get a vector of ISimpleGeometry objects.
		 * 
		 * @return An array of ISimpleGeometry objects which can be used for spatial querying. 
		 */		
		public function getSelectableGeometries():Vector.<ISimpleGeometry>
		{
			_tempArray.length = 0;
			
			var geometryVector:Vector.<ISimpleGeometry> = new Vector.<ISimpleGeometry>();
			var simpleGeom:ISimpleGeometry = new SimpleGeometry(SimpleGeometry.CLOSED_POLYGON);
			var numVertices:int = polygonVertexCount.value;
			var radiusValue:Number = radius.value;
			var angle:Number = 0;
			var dAngle:Number = 2 * Math.PI / numVertices;
			for (var i:int = 0; i < numVertices; ++i)
			{
				// get origin-centered X,Y of the point
				var x:Number = radiusValue * Math.cos(angle);
				var y:Number = radiusValue * Math.sin(angle);
				var p:Point = new Point(x, y);
				
				// offset to the X,Y provided
				p.x += dataX.value;
				p.y += dataY.value;
				
				_tempArray.push(p);
				angle += dAngle;
			}

			(simpleGeom as SimpleGeometry).setVertices(_tempArray);
			geometryVector.push(simpleGeom);
			
			return geometryVector;
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			_tempDataBounds = dataBounds;
			_tempScreenBounds = screenBounds;
			
			if(isNaN(dataX.value) || isNaN(dataY.value) || isNaN(radius.value))
				return;
			
			var g:Graphics = tempShape.graphics;
			g.clear();
			
			//project center point 
			var centerPoint:Point = new Point(dataX.value, dataY.value);
			_tempDataBounds.projectPointTo(centerPoint, _tempScreenBounds);
			
			//project a point on the circle
			var circumferencePoint:Point = new Point(dataX.value + radius.value, dataY.value);
			_tempDataBounds.projectPointTo(circumferencePoint, _tempScreenBounds);
			
			//calculate projected distance
			var distance:Number = Point.distance(centerPoint, circumferencePoint);
			
			//draw circle
			g.lineStyle(thickness.value, color.value, 1.0);
			g.drawCircle(centerPoint.x, centerPoint.y, distance);
			
			destination.draw(tempShape);
		}

		// reusable objects
		
		private var _tempDataBounds:IBounds2D;
		private var _tempScreenBounds:IBounds2D;
		private const _tempArray:Array = [];
	}
}