package weave.ui
{
	import mx.controls.List;
	import mx.core.ClassFactory;
	
	public class ListCheckBoxRadioComponent extends List
	{
		public function ListCheckBoxRadioComponent()
		{
			super();
			selectable = false;
		}
		
		public function setDisplayMode(checkboxes:Boolean):void
		{
			var factory:ClassFactory;
			//set display to checkboxes
			if( checkboxes )
			{
				factory = new ClassFactory(CheckBoxRenderer);
			}
				//set display to radiobutton
			else
			{
				factory = new ClassFactory(RadioButtonRenderer);
			}
			this.itemRenderer = factory;
		}
	}
}