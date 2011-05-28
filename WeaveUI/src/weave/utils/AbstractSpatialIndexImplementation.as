package weave.utils
{
	import flash.utils.Dictionary;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISpatialIndexImplementation;
	import weave.primitives.KDTree;

	/**
	 * This is an abstract class of common methods for each ISpatialIndexImplementation object.
	 * 
	 * @author kmonico
	 */
	public class AbstractSpatialIndexImplementation implements ISpatialIndexImplementation
	{
		protected var _keyToBoundsMap:Dictionary = new Dictionary();
		protected var _plotter:IPlotter = null;
		protected var _kdTree:KDTree = new KDTree(5);
		protected var _keys:Array = null;
		
		public function AbstractSpatialIndexImplementation(plotter:ILinkableObject)
		{
			_plotter = plotter as IPlotter;
		}
		
		public function setKeySource(keys:Array):void
		{
			_keys = keys;
		}
		
		public function getAutoBalance():Boolean
		{
			return _kdTree.autoBalance;
		}
		
		public function insertKey(bounds:IBounds2D, key:IQualifiedKey):void
		{
			_kdTree.insert([bounds.getXNumericMin(), bounds.getYNumericMin(), bounds.getXNumericMax(), bounds.getYNumericMax(), bounds.getArea()], key);
		}
		
		public function getKeys():Array
		{
			return _keys;
		}
		
		public function getRecordCount():int
		{
			return _kdTree.nodeCount;
		}
			
		public function clearTree():void
		{
			_kdTree.clear();
		}
		
		public function cacheKey(key:IQualifiedKey):void
		{
			_keyToBoundsMap[key] = _plotter.getDataBoundsFromRecordKey(key);
		}
		
		public function getBoundsFromKey(key:IQualifiedKey):Array
		{
			var result:Array = _keyToBoundsMap[key] as Array;
			
			if (result == null)
				result = [];
			
			return result;
		}
		
		/* abstract */ public function getKeysContainingBoundsCenter(bounds:IBounds2D, stopOnFirstFind:Boolean = true, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			return null;
		}
		
		/* abstract */ public function getKeysContainingBounds(bounds:IBounds2D, xPrecision:Number = NaN, yPrecision:Number = NaN):Array
		{
			return null;
		}
		
		/**
		 * This function will find all keys whose collective bounds overlap the given bounds object.
		 * The collective bounds is defined as a rectangle which contains every point in the key.
		 * 
		 * @param bounds The bounds for the spatial query.
		 * @param minImportance The minimum importance of which to query.
		 * @return An array of keys with bounds that overlap the given bounds with the specific importance.
		 */		
		public function getKeysInRectangularRange(bounds:IBounds2D, minImportance:Number = 0):Array
		{
			// set the minimum query values for shape.bounds.xMax, shape.bounds.yMax
			minKDKey[XMAX_INDEX] = bounds.getXNumericMin(); // enforce result.XMAX >= query.xNumericMin
			minKDKey[YMAX_INDEX] = bounds.getYNumericMin(); // enforce result.YMAX >= query.yNumericMin
			minKDKey[IMPORTANCE_INDEX] = minImportance; // enforce result.IMPORTANCE >= minImportance
			// set the maximum query values for shape.bounds.xMin, shape.bounds.yMin
			maxKDKey[XMIN_INDEX] = bounds.getXNumericMax(); // enforce result.XMIN <= query.xNumericMax
			maxKDKey[YMIN_INDEX] = bounds.getYNumericMax(); // enforce result.YMIN <= query.yNumericMax
			
			return _kdTree.queryRange(minKDKey, maxKDKey);
		}
		
		/**
		 * These constants define indices in a KDKey corresponding to xmin,ymin,xmax,ymax,importance values.
		 */
		private const XMIN_INDEX:int = 0, YMIN_INDEX:int = 1;
		private const XMAX_INDEX:int = 2, YMAX_INDEX:int = 3;
		private const IMPORTANCE_INDEX:int = 4;
		
		/**
		 * These KDKey arrays are created once and reused to avoid unnecessary creation of objects.
		 * The only values that change are the ones that are undefined here.
		 */
		private var minKDKey:Array = [Number.NEGATIVE_INFINITY, Number.NEGATIVE_INFINITY, NaN, NaN, 0];
		private var maxKDKey:Array = [NaN, NaN, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY];

	}
}