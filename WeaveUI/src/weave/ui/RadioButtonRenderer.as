package weave.ui
{
	import flash.events.Event;
	
	import mx.controls.RadioButton;
	
	import weave.api.data.IAttributeColumn;
	import weave.utils.ColumnUtils;
	
	public class RadioButtonRenderer extends RadioButton
	{
		public function RadioButtonRenderer()
		{
			super();
			this.addEventListener(Event.CHANGE, onChangeHandler);
		}
		
		// Override the set method for the data property.
		override public function set data(value:Object):void {
			super.data = value;
			
			// => Make sure there is data 
			if (value != null) {
				// => Set the label
				this.label = value[0] as String;
				if( value[1] == true )
					this.selected = true;
				else
					this.selected = false;
			}
			
			// => Invalidate display list,
			// => If checkbox is now selected, we need to redraw
			super.invalidateDisplayList();
		}
		
		// => Handle selection change
		private function onChangeHandler(event:Event):void
		{
			super.data[1] = true;
		}
	}
}