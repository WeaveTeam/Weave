package weave.visualization.plotters
{
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
	import spark.primitives.supportClasses.FilledElement;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
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
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (!(task.asyncState is Function))
			{
				var _heightColumns:Array;
				var graphics:Graphics = tempShape.graphics;
				var numHeightColumns:int;
				var clipRectangle:Rectangle = new Rectangle();
				
				task.asyncState = function():Number
				{
					if (task.iteration == 0)
					{
						//Initial setup stuff for each complete drawing of the plot.
						_heightColumns = heightColumns.getObjects();
						
						numHeightColumns = _heightColumns.length;
						
						task.screenBounds.getRectangle(clipRectangle, true);
						clipRectangle.width++; // avoid clipping lines
						clipRectangle.height++; // avoid clipping lines
					}
					if (task.iteration < task.recordKeys.length)
					{
						//Each draw call.
						return task.iteration / task.recordKeys.length;
					}
					//Case for when there is no record keys.
					return 1;
				}
			}
			return (task.asyncState as Function).apply(this, arguments);
		}
	}
}