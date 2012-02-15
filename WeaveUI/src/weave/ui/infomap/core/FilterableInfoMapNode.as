package weave.ui.infomap.core
{
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableString;

	public class FilterableInfoMapNode extends InfoMapNode
	{
		public function FilterableInfoMapNode()
		{
		}
		
		
		/**
		 * @public 
		 * a range of dates to filter documents handled by the node
		 * */ 
		public const dateFilter:DateRangeFilter = newLinkableChild(this,DateRangeFilter);
		
		
		/**
		 * @public
		 * This will hold the source names to query on. It is a comma separate list of names
		 **/
		public const sources:LinkableString = registerLinkableChild(this,new LinkableString('',null,false));
		
	}
}