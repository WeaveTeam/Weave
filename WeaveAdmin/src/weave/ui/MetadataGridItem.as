package weave.ui
{
    public class MetadataGridItem
    {
		/**
		 * @param property The name of the metadata item
		 * @param value The starting value of the metadata item
		 */
		public function MetadataGridItem(property:String, value:Object = null)
		{
			this.property = property;
			this.oldValue = value || '';
			this.value = value || '';
		}
		
		public var property:String;
		public var oldValue:Object;
		public var value:Object;
		
		public function get changed():Boolean
		{
			// handle '' versus null
			if (!oldValue && !value)
				return false;
			
			return oldValue != value;
		}
		
		/**
		 * Use this as a placeholder in metadata object to indicate that multiple values exist for a metadata field.
		 */
		public static const MULTIPLE_VALUES_PLACEHOLDER:Object = {toString: lang('(No change)').toString};
    }
}
