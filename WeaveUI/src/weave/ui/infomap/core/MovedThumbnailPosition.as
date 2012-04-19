package weave.ui.infomap.core
{
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.core.LinkableNumber;

	public class MovedThumbnailPosition implements ILinkableObject
	{
		public function MovedThumbnailPosition()
		{
		}
		
		public const xPos:LinkableNumber = newLinkableChild(this,LinkableNumber);
		
		public const yPos:LinkableNumber = newLinkableChild(this,LinkableNumber);
	}
}