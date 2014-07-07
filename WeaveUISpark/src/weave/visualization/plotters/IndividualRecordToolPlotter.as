package weave.visualization.plotters
{
	import spark.primitives.supportClasses.FilledElement;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.SortedIndexColumn;
	import weave.visualization.plotters.styles.SolidFillStyle;

	public class IndividualRecordToolPlotter extends AbstractPlotter
	{
		public const heightColumns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn));
		public const showLabels:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const fill:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		private const _binnedSortColumn:BinnedColumn = newSpatialProperty(BinnedColumn); // only used when groupBySortColumn is true
		private const _sortedIndexColumn:SortedIndexColumn = _binnedSortColumn.internalDynamicColumn.requestLocalObject(SortedIndexColumn, true); // this sorts the records
		private const _filteredSortColumn:FilteredColumn = _sortedIndexColumn.requestLocalObject(FilteredColumn, true); // filters before sorting
		public function get sortColumn():DynamicColumn { return _filteredSortColumn.internalDynamicColumn; }
		
		public function IndividualRecordToolPlotter()
		{
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
		}
		
		public function sortAxisLabelFunction(value:Number):String
		{
			//Create label function.
			return "test";
		}
		
		public function get maxTickMarks():int
		{
			//to be implemented.
			return 10;
		}
	}
}