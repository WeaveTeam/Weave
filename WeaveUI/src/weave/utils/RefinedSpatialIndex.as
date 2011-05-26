package weave.utils
{
	import flash.utils.Dictionary;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISpatialIndexImplementation;
	import weave.core.CallbackCollection;

	/**
	 * This is an implementation of a SpatialIndex for a general IPlotter object.
	 * 
	 * @author kmonico
	 */
	public class RefinedSpatialIndex implements ISpatialIndexImplementation
	{
		public function RefinedSpatialIndex(plotter:ILinkableObject)
		{
			_plotter = plotter as IPlotter;
		}
		
		private var _plotter:IPlotter = null;
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
			_keyToBoundsMap[key] = _plotter.getDataBoundsFromRecordKey(key);
		}
		
		
		/**
		 * @param bounds A bounds used to query the spatial index.
		 * @param xPrecision If specified, X distance values will be divided by this and truncated before comparing.
		 * @param yPrecision If specified, Y distance values will be divided by this and truncated before comparing.
		 * @return An array of keys with bounds that overlap the given bounds and are closest to the center of the given bounds.
		 */
		public function getKeysContainingBoundsCenter(keys:Array, bounds:IBounds2D, stopOnFirstFind:Boolean = true, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			// init local vars
			var closestDistanceSq:Number = Infinity;
			var xDistance:Number;
			var yDistance:Number;
			var distanceSq:Number;
			var xRecordCenter:Number;
			var yRecordCenter:Number;
			var recordBounds:IBounds2D;
			var xQueryCenter:Number = bounds.getXCenter();
			var yQueryCenter:Number = bounds.getYCenter();
			var foundQueryCenterOverlap:Boolean = false; // true when we found a key that overlaps the center of the given bounds
			// begin with a result of zero shapes
			var result:Array = [];
			var resultCount:int = 0;
			for each (var key:IQualifiedKey in keys)
			{
				for each (recordBounds in _keyToBoundsMap[key])
				{
					// find the distance squared from the query point to the center of the shape
					xDistance = recordBounds.getXCenter() - xQueryCenter;
					yDistance = recordBounds.getYCenter() - yQueryCenter;
					if (!isNaN(xPrecision) && xPrecision != 0)
						xDistance = int(xDistance / xPrecision);
					if (!isNaN(yPrecision) && yPrecision != 0)
						yDistance = int(yDistance / yPrecision);
					distanceSq = xDistance * xDistance + yDistance * yDistance;
					var overlapsQueryCenter:Boolean = recordBounds.contains(xQueryCenter, yQueryCenter);
					// Consider all keys until we have found one that overlaps the query center.
					// After that, only consider keys that overlap query center.
					if (!foundQueryCenterOverlap || overlapsQueryCenter)
					{
						// if this is the first record that overlaps the query center, reset the list of keys
						if (!foundQueryCenterOverlap && overlapsQueryCenter)
						{
							resultCount = 0;
							closestDistanceSq = Infinity;
							foundQueryCenterOverlap = true;
						}
						// if this distance is closer than any previous distance, clear all previous keys
						if (distanceSq < closestDistanceSq)
						{
							// clear previous result and update closest distance
							resultCount = 0;
							closestDistanceSq = distanceSq;
						}
						// add keys to the result if they are the closest so far
						if (distanceSq == closestDistanceSq && (resultCount == 0 || result[resultCount - 1] != key))
							result[resultCount++] = key;
					}
				}
			}
			result.length = resultCount;
			return result;
		}
	}
}