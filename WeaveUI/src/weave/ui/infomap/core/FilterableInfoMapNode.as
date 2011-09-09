package weave.ui.infomap.core
{
	import weave.api.newLinkableChild;
	import weave.core.LinkableString;

	public class FilterableInfoMapNode extends InfoMapNode
	{
		public function FilterableInfoMapNode()
		{
		}
		
		/**
		 * @public 
		 * A search filter to search within documents handled by this node. 
		 * */ 
		public const searchFilter:LinkableString = newLinkableChild(this,LinkableString);
		
		/**
		 * @public 
		 * a range of dates to filter documents handled by the node
		 * */ 
		public const dateFilter:DateRangeFilter = newLinkableChild(this,DateRangeFilter);
	}
}