/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.visualization.plotters
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Point;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotterWithGeometries;
	import weave.core.LinkableNumber;
	import weave.primitives.GeometryType;
	import weave.primitives.SimpleGeometry;

	/**
	 * 
	 * @author skolman
	 * @author kmonico
	 */	
	public class CirclePlotter extends AbstractPlotter implements IPlotterWithGeometries
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
		
		[Deprecated(replacement="lineColor")] public function set color(value:Object):void
		{
			setSessionState(lineColor, value);
		}
		
		/**
		 * The color of the circle.
		 * @default 0 
		 */		
		public const lineColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0, verifyColor));
		/**
		 * The alpha of the circle.
		 * @default 1 
		 */		
		public const lineAlpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1, verifyAlpha));
		/**
		 * The color of the fill inside the circle.
		 * @default 0 
		 */		
		public const fillColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0, verifyColor));
		/**
		 * The alpha of the fill inside the circle.
		 * @default 0 
		 */		
		public const fillAlpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0, verifyAlpha));

		/**
		 * The thickness of the edge of the circle. 
		 */		
		public const thickness:LinkableNumber = registerLinkableChild(this, new LinkableNumber(2));
		
		/**
		 * The projection of the map when this circle was created. 
		 */		
		//public const projectionSRS:LinkableString = registerLinkableChild(this, new LinkableString('', WeaveAPI.ProjectionManager.projectionExists));
		
		/**
		 * The number of vertices to use inside the polygon when selecting records. This must be at
		 * least <code>3</code>. <br>
		 * @default <code>25</code>
		 */		
		public const polygonVertexCount:LinkableNumber = registerLinkableChild(this, new LinkableNumber(25, verifyPolygonVertexCount));
		private function verifyPolygonVertexCount(value:Number):Boolean
		{
			return value >= 3; 
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
			g.lineStyle(thickness.value, lineColor.value, lineAlpha.value);
			g.beginFill(fillColor.value, fillAlpha.value);
			g.drawCircle(centerPoint.x, centerPoint.y, distance);
			
			destination.draw(tempShape);
		}

		public function getGeometriesFromRecordKey(recordKey:IQualifiedKey, minImportance:Number = 0, bounds:IBounds2D = null):Array
		{
			// no keys in this plotter
			return [];
		}
		
		public function getBackgroundGeometries():Array
		{
			_tempArray.length = 0;
			
			var geometryVector:Array = [];
			var simpleGeom:ISimpleGeometry = new SimpleGeometry(GeometryType.POLYGON);
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
		
				
		private function verifyColor(value:Number):Boolean
		{
			return value >= 0;
		}
		
		private function verifyAlpha(value:Number):Boolean
		{
			return value >= 0 && value <= 1;
		}
		// reusable objects
		
		private var _tempDataBounds:IBounds2D;
		private var _tempScreenBounds:IBounds2D;
		private const _tempArray:Array = [];
	}
}