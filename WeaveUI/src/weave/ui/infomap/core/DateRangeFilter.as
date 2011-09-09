package weave.ui.infomap.core
{
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.core.LinkableString;

	public class DateRangeFilter implements ILinkableObject
	{
		/**
		 * An object of this class can be used to assign a date range as a filter to a node or
		 * the infomap panel.
		 * It has 2 Linkable String variables: startDate and endDate
		 * */
		public function DateRangeFilter()
		{
		}
		
		public const startDate:LinkableString = newLinkableChild(this,LinkableString);
		public const endDate:LinkableString = newLinkableChild(this,LinkableString);
		
	}
}