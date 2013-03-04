package weave.ui
{
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.controls.Label;
	
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;

	public class KeyTypesMenu extends HBox
	{
		private var menuLabel:Label = new Label();
		private var comboBox:CustomComboBox = new CustomComboBox();
		public function KeyTypesMenu()
		{
			menuLabel.text = lang("Select Keytype");
			comboBox.toolTip=lang('The keytype is used to link your dataset with other data sets and shapefiles. Data sets and shapefiles with the same keytype are linked. Select from the options provided here or enter your own keytype.');
			comboBox.editable= true; 
			addElement(menuLabel);
			addElement(comboBox);
			getCallbackCollection(WeaveAPI.QKeyManager).addGroupedCallback(this,handleQKeyManagerChange,true);
		}
		
		/**
		 * Sets the width of the label component.
		 * */
		public function set indent(value:int):void
		{
			menuLabel.width = value; 
		}
		
		/**
		 * Returns the text of the label component
		 * */
		public function get labelText():String
		{
			return menuLabel.text; 
		}
		
		/**
		 * Sets the text of the label component
		 * */
		public function set labelText(value:String):void
		{
			menuLabel.text = value;
		}
		
		/**
		 * Adds a Keytype of type string to the menu. 
		 * @param keyType the keytype to add. 
		 * @param addToTop set true if the keytype should appear at the top of the menu. If false, keytype appears at the bottom.
		 * */
		public function addKeyTypeToMenu(keytype:String,addToTop:Boolean=true):void
		{
			var keytypesSource:ArrayCollection = comboBox.dataProvider as ArrayCollection;
			
			if(keytypesSource.contains(keytype))
				return;
			
			if(addToTop)
				keytypesSource.addItemAt(keytype,0);
			else
				keytypesSource.addItem(keytype);
			
			comboBox.invalidateDisplayList();//required incase the length of the keytype is longer than other items and it might be cut-off.
		}
		
		/**
		 * Removes a keytype from the menu
		 * @param keyType The keytype to remove.
		 **/
		public function removeKeyTypeFromMenu(keytype:String):void
		{
			var keytypesSource:ArrayCollection = comboBox.dataProvider as ArrayCollection;
			
			var itemIndex:int = keytypesSource.getItemIndex(keytype);
			
			if(itemIndex > -1)
				keytypesSource.removeItemAt(itemIndex);
		}
		
		/**
		 * Returns the selected item from the menu
		 **/
		public function get selectedItem():Object
		{
			return comboBox.text;//we use text and not selectedItem because user can enter the keytype
		}
		
		public function set selectedItem(item:Object):void
		{
			comboBox.selectedItem = item;	
		}
		
		private function handleQKeyManagerChange():void
		{
			var keytypes:Array = WeaveAPI.QKeyManager.getAllKeyTypes();
			for each(var keytype:String in keytypes)
			{
				addKeyTypeToMenu(keytype,false);
			}
			
			comboBox.invalidateDisplayList();
		}
	}
}