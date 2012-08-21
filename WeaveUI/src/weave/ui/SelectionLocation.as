package weave.ui
{
	import weave.core.LinkableString;
	
	public class SelectionLocation
	{
		public static const selectionLocationMode:LinkableString = new LinkableString(SELECTION_LOCATION_LOWER_LEFT, verifyLocationMode);
		
		public static const SELECTION_LOCATION_LOWER_LEFT:String = 'Lower left';
		public static const SELECTION_LOCATION_LOWER_RIGHT:String = 'Lower right';
		public static function get selectionLocationEnum():Array
		{
			return [SELECTION_LOCATION_LOWER_LEFT, SELECTION_LOCATION_LOWER_RIGHT];
		}
		
		private static function verifyLocationMode(value:String):Boolean
		{
			return selectionLocationEnum.indexOf(value) >= 0;
		}
		
		public function SelectionLocation()
		{
		}
	}
}