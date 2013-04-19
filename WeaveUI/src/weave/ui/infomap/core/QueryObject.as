package weave.ui.infomap.core
{
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.primitives.DateRangeFilter;
	
	public class QueryObject implements ILinkableObject
	{
		public function QueryObject()
		{
		}
		
		/**
		 * @public 
		 * The keywords is the query made when this node was requested
		 * */ 
		public const keywords:LinkableString = newLinkableChild(this,LinkableString);
		
		/**
		 * @public 
		 * Only two Operators are valid: AND,OR
		 * AND will search for documents containing all the keywords
		 * OR will search for documents containing any of the keywords
		 * */ 
		public const operator:LinkableString = registerLinkableChild(this,new LinkableString('AND',operatorVerifier,false));
		
		private function operatorVerifier(value:*):Boolean
		{
			if((value as String) == 'OR' || (value as String) == 'AND' )
				return true;
			else 
				return false;
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
		
		public const sortBy:LinkableString = registerLinkableChild(this, new LinkableString("Relevance",function(value:*):Boolean{
			if(value == 'Relevance' || value == 'Date')
				return true;
			else
				return false;
		},false));
	}
}