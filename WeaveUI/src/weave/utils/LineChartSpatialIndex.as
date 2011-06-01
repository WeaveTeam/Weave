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

package weave.utils
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.primitives.Bounds2D;
	import weave.primitives.LineSegment;
	import weave.visualization.plotters.LinePlotter;
	import weave.visualization.plotters.ParallelCoordinatesPlotter;
	
	/**
	 * This class is the implementation of a spatial index for the LineChart Tool. 
	 *
	 * @author kmonico
	 */
	public class LineChartSpatialIndex extends AbstractSpatialIndexImplementation
	{
		public function LineChartSpatialIndex(plotter:ILinkableObject)
		{
			_pCoordsPlotter = plotter as ParallelCoordinatesPlotter;

			super(plotter);
		}
		
		private var _pCoordsPlotter:ParallelCoordinatesPlotter = null;
		private const _xMinArray:Vector.<Number> = new Vector.<Number>();
		private var _numColumns:int;
		
		/** 
		 * IQualifiedKey --> Number
		 * This is a cache filled with the last getKeysContainingBounds calls
		 * Each value is the distance from the center of the query bounds to the 
		 * line which intersects the query bounds.
		 */		
		private const _keyToLastDistance:Dictionary = new Dictionary();
		
		override public function cacheKey(key:IQualifiedKey):void
		{
			// cache the key's bounds array
			var boundsArray:Array = _pCoordsPlotter.getDataBoundsFromRecordKey(key);
			boundsArray.sort(sortBounds);
			
			if (boundsArray.length != _xMinArray.length)
			{
				// for each bounds, save the xMin value. We need this elsewhere for figuring out which columns
				// to check during probing.
				for (var i:int = _xMinArray.length; i < boundsArray.length; ++i)
				{
					_xMinArray.push((boundsArray[i] as Bounds2D).xMin);
				}
			}
			
			_keyToBoundsMap[key] = boundsArray;
			_numColumns = boundsArray.length;
		}
		
		/**
		 * This is the comparison function passed into a sort function in cacheKey. This function defines 
		 * the ordering in the sorted array.
		 */
		private function sortBounds(a:IBounds2D, b:IBounds2D):int
		{
			var aMin:Number = a.getXMin();
			var bMin:Number = b.getXMin();
			
			if (aMin == bMin)
				return 0;
			if (aMin < bMin)
				return -1;
			
			// else (bMin > aMin)
			return 1;
		}		
		
		override public function getClosestOverlappingKeys(bounds:IBounds2D, stopOnFirstFind:Boolean = true, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			var keys:Array = getKeysContainingBounds(bounds, xPrecision, yPrecision);
			
			// now filter the keys to get only the closest one. 
			var closestKey:IQualifiedKey = null;
			var closestDistance:Number = Number.POSITIVE_INFINITY; 
			for each (var key:IQualifiedKey in keys)
			{
				var value:Number = _keyToLastDistance[key];
				
				if (value < closestDistance)
				{
					closestDistance = value;
					closestKey = key;
				}
			}
			
			// do NOT return null because other code expects an array always
			if (closestKey == null)
				return [];
			
			return [ closestKey ];
		}

		override public function getKeysContainingBounds(bounds:IBounds2D, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			// first get the keys with points which overlap
			var knownKeys:Array = super.getKeysInRectangularRange(bounds, 0);
			
			var xMin:Number = bounds.getXMin();
			var xMax:Number = bounds.getXMax();
			// figure out which columns are immediately to the left and right
			var iLeft:int = 0;
			var iRight:int = 0;
			for (var i:int = 0; i < _xMinArray.length; ++i)
			{
				if (xMin > _xMinArray[i])
					iLeft = i;
				if (xMax < _xMinArray[i])
				{
					iRight = i;
					break;
				}
			}
			
			bounds.getCenterPoint(_tempQueryCenterPoint);
			
			// we'll check if the left if iLeft and iLeft+1 are indices for the _xMinArray
			var doLeftCheck:Boolean = (iLeft + 1) < _numColumns;
			// and check the right if iRight - 1 >= 0 and iRight - 1 != iLeft
			var doRightCheck:Boolean = ((iRight - 1) >= 0) && (iLeft != (iRight - 1));
			
			// for each key, check if the line from iLeft bounds to iLeft+1 bounds is in query bounds
			// and check if the line from iRight-1 bounds to iRight bounds is in query bounds
			var result:Array = [];
			for each (var key:IQualifiedKey in _keys)
			{
				if (knownKeys.indexOf(key) >= 0)
					continue;
				
				var keyBounds:Array = _keyToBoundsMap[key];
				
				// check left // test
				if (doLeftCheck)
				{
					var leftBounds1:IBounds2D = keyBounds[iLeft];
					var leftBounds2:IBounds2D = keyBounds[iLeft + 1];
					leftBounds1.getCenterPoint(_tempPoint1);
					leftBounds2.getCenterPoint(_tempPoint2);
					_tempLineSegment.beginPoint = _tempPoint1;
					_tempLineSegment.endPoint = _tempPoint2; 
					if (ComputationalGeometryUtils.lineCrossesBounds(_tempLineSegment, bounds))
					{
						// save the key and compute the distance from the line to the center of the bounds
						result.push(key); 
						_keyToLastDistance[key] = ComputationalGeometryUtils.linePointDistanceSq(_tempLineSegment, _tempQueryCenterPoint);
						continue;
					}
				}
				
				// check right
				if (doRightCheck)
				{
					var rightBounds1:IBounds2D = keyBounds[iRight];
					var rightBounds2:IBounds2D = keyBounds[iRight - 1];
					rightBounds1.getCenterPoint(_tempPoint1);
					rightBounds2.getCenterPoint(_tempPoint2);
					_tempLineSegment.beginPoint = _tempPoint1;
					_tempLineSegment.endPoint = _tempPoint2; 
					if (ComputationalGeometryUtils.lineCrossesBounds(_tempLineSegment, bounds))
					{
						// save the key and compute the distance from the line to the center of the bounds
						result.push(key);
						_keyToLastDistance[key] = ComputationalGeometryUtils.linePointDistanceSq(_tempLineSegment, _tempQueryCenterPoint); 
						continue;
					}
				}
			}
			
			return result.concat(knownKeys);
		} 
		
		private const _tempLineSegment:LineSegment = new LineSegment();
		private const _tempPoint1:Point = new Point();
		private const _tempPoint2:Point = new Point();
		private const _tempQueryCenterPoint:Point = new Point();
	}
}