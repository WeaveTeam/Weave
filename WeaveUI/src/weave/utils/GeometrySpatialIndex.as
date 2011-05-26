package weave.utils
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISpatialIndexImplementation;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.ReprojectedGeometryColumn;
	import weave.primitives.BLGNode;
	import weave.primitives.GeneralizedGeometry;
	import weave.primitives.LineRay;
	import weave.primitives.LineSegment;
	import weave.visualization.plotters.GeometryPlotter;

	/**
	 * This class is a SpatialIndex implementation intended for GeometryPlotters. It uses
	 * many algorithms from computational geometry to solve probing issues.
	 * 
	 * @author kmonico
	 */
	public class GeometrySpatialIndex implements ISpatialIndexImplementation
	{
		public function GeometrySpatialIndex(plotter:ILinkableObject)
		{
			var geomPlotter:GeometryPlotter = plotter as GeometryPlotter;
			_geomPlotter = geomPlotter;
			_geomColumn = geomPlotter.geometryColumn;
		}

		private var _geomColumn:ReprojectedGeometryColumn = null;
		private var _geomPlotter:GeometryPlotter = null;
		private var _keyToBoundsMap:Dictionary = new Dictionary();
		
		public function getBoundsFromKey(key:IQualifiedKey):Array
		{
			var result:Array = _keyToBoundsMap[key] as Array;
			if (result == null)
			{
				result = [];
			}
			
			return result;
		}
				
		public function cacheKey(key:IQualifiedKey):void
		{
			_keyToBoundsMap[key] = _geomPlotter.getDataBoundsFromRecordKey(key);
		}
		

		public function getKeysContainingBoundsCenter(keys:Array, bounds:IBounds2D, stopOnFirstFind:Boolean = true, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			var result:Array = [];
			if (keys.length == 0)
				return result;
			
			var xQueryCenter:Number = bounds.getXCenter();
			var yQueryCenter:Number = bounds.getYCenter();
			var queryRay:LineRay = new LineRay(xQueryCenter, yQueryCenter);

			var importance:Number;
			if (isNaN(xPrecision) || isNaN(yPrecision))
				importance = 0;
			else
				importance = xPrecision * yPrecision;
			
			var foundPart:Boolean = false;

			// for each key, get its geometries. Notice the use of the label to quickly exit the loop.
			outerLoop: for (var iKey:int = 0; iKey < keys.length; ++iKey)
			{
				var key:IQualifiedKey= keys[iKey];
				//var column:IAttributeColumn = _keyToGeometryColumn[key] as IAttributeColumn;
				var geoms:Array = _geomColumn.getValueFromKey(key) as Array;
				if (geoms == null)
					continue;
				
				// for each geom, check if one of its parts contains the point using ray casting
				for (var iGeom:int = 0; iGeom < geoms.length; ++iGeom)
				{
					// the current geometry
					var geom:GeneralizedGeometry = geoms[iGeom] as GeneralizedGeometry;

					// get the simplified geometry as a vector of parts
					var simplifiedGeom:Vector.<Vector.<BLGNode>> = geom.getSimplifiedGeometry(importance, bounds); 
					
					// for each part, go through the coordinates building a segment and checking if a ray from the
					// query center intersects it
					for (var iPart:int = 0; iPart < simplifiedGeom.length; ++iPart)
					{
						//_tempLineSegments.length = 0; // TODO: reuse the line segments but discard unused ones after the following part
						var currentPart:Vector.<BLGNode> = simplifiedGeom[iPart];
						var intersectionCount:int = 0;
						
						var kPoint:int = 0;
						var currentNode:BLGNode;
						// iterate through the points, two at a time
			
						while (kPoint < currentPart.length)
						{
							// store the first point of the segment
							currentNode = currentPart[kPoint];  
							_tempPoint1.x = currentNode.x;
							_tempPoint1.y = currentNode.y;
							++kPoint; // increment iterator
							
							// check if we're at the end of the vector of nodes
							if (kPoint == currentPart.length)
							{
								// set the first point of the part to be p2
								currentNode = currentPart[0];
							}
							else // still more points to read
							{
								// use the next point in the part
								currentNode = currentPart[kPoint];
							}
							
							_tempPoint2.x = currentNode.x;
							_tempPoint2.y = currentNode.y;
							
							// build the segment and check if the ray intersects it
							_tempLineSegment.beginPoint = _tempPoint1;
							_tempLineSegment.endPoint = _tempPoint2;
							_tempLineSegment.makeSlopePositive();
							if (ComputationalGeometryUtils.doesLineIntersectRay(_tempLineSegment, queryRay))
								++intersectionCount;
						}
						
						if (intersectionCount % 2 == 1 && kPoint > 0)
						{
							foundPart = true; // we found a part
							result.push(keys[iKey]); // save the key
							//trace((keys[iKey] as IQualifiedKey).keyType, (keys[iKey] as IQualifiedKey).localName);
							
							// determine whether to exit this main loop or continue
							if (stopOnFirstFind == true) 
								break outerLoop;
							else
								continue outerLoop;
						} // end if
					} // end part loop
				} // end Geometry loop
			} // end outerLoop aka Key loop
			return result;
		} // end function
		
			

		public function getKeysOverlappingBounds(keys:Array, bounds:IBounds2D, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			// NOTE: A lot of this code is duplicated from getKeysContainingBoundsCenter, but this serves a very different
			// purpose. For optimal performance, the operations are done serially so refactoring the duplicated code
			// into a separate function would hurt performance or not be serial.
			var result:Array = [];
			if (keys.length == 0)
				return result;
			
			var xQueryCenter:Number = bounds.getXCenter();
			var yQueryCenter:Number = bounds.getYCenter();
			var queryRay:LineRay = new LineRay(xQueryCenter, yQueryCenter);

			var importance:Number;
			if (isNaN(xPrecision) || isNaN(yPrecision))
				importance = 0;
			else
				importance = xPrecision * yPrecision;
			
			var foundPart:Boolean = false;

			// for each key, get its geometries. Notice the use of the label to quickly exit the loop.
			outerLoop: for (var iKey:int = 0; iKey < keys.length; ++iKey)
			{
				var key:IQualifiedKey= keys[iKey];
				//var column:IAttributeColumn = _keyToGeometryColumn[key] as IAttributeColumn;
				var geoms:Array = _geomColumn.getValueFromKey(key) as Array;
				if (geoms == null)
					continue;
				
				// for each geom, check if one of its parts contains the point using ray casting
				for (var iGeom:int = 0; iGeom < geoms.length; ++iGeom)
				{
					// the current geometry
					var geom:GeneralizedGeometry = geoms[iGeom] as GeneralizedGeometry;

					// get the simplified geometry as a vector of parts
					var simplifiedGeom:Vector.<Vector.<BLGNode>> = geom.getSimplifiedGeometry(importance, bounds); 
					
					// for each part, go through the coordinates building a segment and checking if a ray from the
					// query center intersects it
					for (var iPart:int = 0; iPart < simplifiedGeom.length; ++iPart)
					{
						//_tempLineSegments.length = 0; // TODO: reuse the line segments but discard unused ones after the following part
						var currentPart:Vector.<BLGNode> = simplifiedGeom[iPart];
						
						var kPoint:int = 0;
						var currentNode:BLGNode;
						// iterate through the points, two at a time
			
						while (kPoint < currentPart.length)
						{
							// store the first point of the segment
							currentNode = currentPart[kPoint];  
							_tempPoint1.x = currentNode.x;
							_tempPoint1.y = currentNode.y;
							++kPoint; // increment iterator
							
							// check if we're at the end of the vector of nodes
							if (kPoint == currentPart.length)
							{
								// set the first point of the part to be p2
								currentNode = currentPart[0];
							}
							else // still more points to read
							{
								// use the next point in the part
								currentNode = currentPart[kPoint];
							}
							
							_tempPoint2.x = currentNode.x;
							_tempPoint2.y = currentNode.y;
							
							// build the segment and check if the bounds intersects it
							_tempLineSegment.beginPoint = _tempPoint1;
							_tempLineSegment.endPoint = _tempPoint2;
							_tempLineSegment.makeSlopePositive();
							if (ComputationalGeometryUtils.doesLineCrossBounds(_tempLineSegment, bounds))
							{
								result.push(keys[iKey]);
								continue outerLoop; // move to the next key
							}
						}
					} // end part loop
				} // end Geometry loop
			} // end outerLoop aka Key loop
			return result;
		} // end function
		
		private const _tempLineSegment:LineSegment = new LineSegment();
		private const _tempPoint1:Point = new Point();
		private const _tempPoint2:Point = new Point();
	}
}