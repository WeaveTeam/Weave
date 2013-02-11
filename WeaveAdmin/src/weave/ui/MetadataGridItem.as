package weave.ui
{
    public class MetadataGridItem
    {
		/**
		 * @param property The name of the metadata item
		 * @param value The starting value of the metadata item
		 */
		public function MetadataGridItem(property:String, value:String = null)
		{
			this.property = property;
			this.oldValue = value;
			this.value = value;
		}
		
		public var property:String;
		public var oldValue:String;
		public var value:String;
    }
}
