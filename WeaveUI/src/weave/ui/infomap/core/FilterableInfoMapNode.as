package weave.ui.infomap.core
{
	import flash.utils.getTimer;
	
	import weave.api.WeaveAPI;
	import weave.api.detectLinkableObjectChange;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableString;
	import weave.primitives.DateRangeFilter;
	import weave.utils.DateUtils;

	public class FilterableInfoMapNode extends InfoMapNode
	{
		public function FilterableInfoMapNode()
		{
			WeaveAPI.StageUtils.callLater(this,function():void{reportChange=true},null);
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
		
		public function detectQueryChange(observer:Object):Boolean
		{
			return detectLinkableObjectChange(observer,keywords,dateFilter.startDate,dateFilter.endDate,sources,operator) && reportChange;
		}
		
		private var reportChange:Boolean = false;
		
		
	}
}