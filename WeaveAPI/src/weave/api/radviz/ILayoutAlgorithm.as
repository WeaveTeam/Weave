package weave.api.radviz
{
	import flash.utils.Dictionary;
	
	import weave.api.core.ICallbackCollection;

	/**
	 * An interface for dimensional layout algorithms
	 * 
	 * @author kmanohar
	 */	
	public interface ILayoutAlgorithm extends ICallbackCollection
	{
		/**
		 * Runs the layout algorithm and calls performLayout() 
		 * @param array An array of IAttributeColumns to reorder
		 * @param keyNumberHashMap hash map to speed up computation
		 * @return An ordered array of IAttributeColumns
		 */		
		function run(array:Array, keyNumberHashMap:Dictionary):Array;
		
		/**
		 * Performs the calculations to reorder an array  
		 * @param columns an array of IAttributeColumns
		 */		
		function performLayout(columns:Array):void;		
	}
}