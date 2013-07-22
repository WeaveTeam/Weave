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
		
		public static var FILTER_BY_BOOKS:String= "Books";
		public static var FILTER_BY_PAPERS:String= "Papers";
		public static var FILTER_BY_RSSFEEDS:String = "RssFeeds";
		public static var FILTER_BY_NONE:String = "None";
		
		public static var filterByOptions:Array = [FILTER_BY_NONE,FILTER_BY_BOOKS,FILTER_BY_PAPERS,FILTER_BY_RSSFEEDS];
		//a private array of filter options which includes the empty string. 
		private static var _filterByOptions:Array = [FILTER_BY_BOOKS,FILTER_BY_PAPERS,FILTER_BY_RSSFEEDS,""];
		/**
		 * @public
		 * This will hold the source names to query on. It is a comma separate list of names
		 **/
		public const sources:LinkableString = registerLinkableChild(this,new LinkableString('',function(value:*):Boolean{
			if(_filterByOptions.indexOf(value) != -1)
			{
				return true;
			}
			else
			{
				return false;
			}
			
		},false));
		
		public static var sortByOptions:Array = [SORT_BY_RELEVANCE,SORT_BY_DATE_PUBLISHED,SORT_BY_DATE_ADDED];
		
		public static var SORT_BY_RELEVANCE:String = "Relevance";
		public static var SORT_BY_DATE_PUBLISHED:String = "Date Published";
		public static var SORT_BY_DATE_ADDED:String = "Date Added";
		
		public const sortBy:LinkableString = registerLinkableChild(this, new LinkableString("Relevance",function(value:*):Boolean{
			if(sortByOptions.indexOf(value) != -1)
			{
				return true;
			}
			else
				return false;
		},false));
		
		
		
		/*Function to compare 2 QueryObject instances. Ignores sortBy value*/
		public static function isQueryDifferent(q1:QueryObject, q2:QueryObject):Boolean
		{
			if(q1.keywords.value != q2.keywords.value)
				return true;
			else if(q1.operator.value != q2.operator.value)
				return true;
			else if(q1.dateFilter.startDate.value != q2.dateFilter.startDate.value)
				return true;
			else if(q1.dateFilter.endDate.value != q2.dateFilter.endDate.value)
				return true;
			else if(q1.sources.value != q2.sources.value)
				return true;
			else return false;
		}
		
		public static function isSortByDifferent(q1:QueryObject, q2:QueryObject):Boolean
		{
			if(q1.sortBy.value != q2.sortBy.value)
				return true;
			else 
				return false;
		}
		
	}
}