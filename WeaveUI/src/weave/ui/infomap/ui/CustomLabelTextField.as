package weave.ui.infomap.ui
{
	import mx.controls.Label;
	import mx.core.IUITextField;
	import mx.core.UITextField;

	public class CustomLabelTextField extends Label
	{
		public function CustomLabelTextField()
		{
			super();
		}
		
		public function getTextField():IUITextField
		{
			return textField;
		}
	}
}