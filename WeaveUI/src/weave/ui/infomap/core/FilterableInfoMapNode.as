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
		
		/**
		 *This function compares 2 FilterableInfoMapNode and returns true only if the keywords, date filter and the sources have the same values 
		 * @param node The FilterableInfoMapNode to compare this object with
		 * @return True if they have the same values
		 * 
		 */		
		public function compareWith(node:FilterableInfoMapNode):Boolean
		{
			if(!node.keywords.value || !this.keywords.value)
				return false;
			
			if(this.keywords.value.toLowerCase() != node.keywords.value.toLowerCase())
				return false;
			
			if(this.operator.value.toLowerCase() != node.operator.value.toLowerCase())
				return false;
			
			if(this.sources.value.toLowerCase() != node.sources.value.toLowerCase())
				return false;

			var startDate:Date = DateUtils.getDateFromString(this.dateFilter.startDate.value);
			var endDate:Date = DateUtils.getDateFromString(this.dateFilter.endDate.value);
			
			var nodeStartDate:Date = DateUtils.getDateFromString(node.dateFilter.startDate.value); 
			var nodeEndDate:Date = DateUtils.getDateFromString(node.dateFilter.endDate.value);
			
			if((!startDate && nodeStartDate) || (startDate && !nodeStartDate))
				return false;
			
			if(startDate && endDate)
				if(startDate.getTime() != nodeStartDate.getTime())
					return false;
			
			if((!endDate && nodeEndDate) || (endDate && !nodeEndDate))
				return false;
			
			if(endDate && nodeEndDate)
				if(endDate.getTime() != nodeEndDate.getTime())
					return false;
			
			
			
			return true;
		}
		
		public function copyNode(node:FilterableInfoMapNode):void
		{
			this.dateFilter.endDate.value = node.dateFilter.endDate.value;
			this.dateFilter.startDate.value = node.dateFilter.startDate.value;
			
			this.keywords.value = node.keywords.value;
			
			this.sources.value = node.sources.value;
			
		}
		
		public function detectQueryChange(observer:Object):Boolean
		{
			return detectLinkableObjectChange(observer,keywords,dateFilter.startDate,dateFilter.endDate,sources,operator) && reportChange;
		}
		
		private var reportChange:Boolean = false;
		
		
	}
}