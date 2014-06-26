package weave.visualization.plotters
{
	import spark.primitives.supportClasses.FilledElement;
	
	import weave.Weave;
	import weave.api.newLinkableChild;
	import weave.visualization.plotters.styles.SolidFillStyle;

	public class IndividualRecordToolPlotter extends AbstractPlotter
	{
		
		public const fill:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		
		public function IndividualRecordToolPlotter()
		{
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
		}
	}
}