package weave.ui
{
	import mx.collections.ArrayCollection;
	
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;
	import weave.utils.EventUtils;

	public class KeyTypesMenu extends CustomComboBox
	{
		public function KeyTypesMenu()
		{
			toolTip = lang('The keytype is used to link your dataset with other data sets and shapefiles. Data sets and shapefiles with the same keytype are linked. Select from the options provided here or enter your own keytype.');
			editable = true; 
			getCallbackCollection(WeaveAPI.QKeyManager).addGroupedCallback(this,handleQKeyManagerChange);
			handleQKeyManagerChange();
			EventUtils.doubleBind(this, 'selectedKeyType', this, 'text');
		}
		
		/**
		 * Adds a Keytype of type string to the menu. 
		 * @param keyType the keytype to add. 
		 * @param addToTop set true if the keytype should appear at the top of the menu. If false, keytype appears at the bottom.
		 * */
		public function addKeyTypeToMenu(keytype:String,addToTop:Boolean=true):void
		{
			_addKeyTypeToMenu(keytype, addToTop);
			invalidateDisplayList();//required incase the length of the keytype is longer than other items and it might be cut-off.
			validateNow();
		}
		private function _addKeyTypeToMenu(keytype:String,addToTop:Boolean=true):void
		{
			var keytypesSource:ArrayCollection = dataProvider as ArrayCollection;
			
			if(keytypesSource.contains(keytype))
				return;
			
			if(addToTop)
				keytypesSource.addItemAt(keytype,0);
			else
				keytypesSource.addItem(keytype);
		}
		
		/**
		 * Removes a keytype from the menu
		 * @param keyType The keytype to remove.
		 **/
		public function removeKeyTypeFromMenu(keytype:String):void
		{
			var keytypesSource:ArrayCollection = dataProvider as ArrayCollection;
			
			var itemIndex:int = keytypesSource.getItemIndex(keytype);
			
			if(itemIndex > -1)
				keytypesSource.removeItemAt(itemIndex);
		}
		
		/**
		 * Returns the selected item from the menu
		 **/
		[Bindable] public var selectedKeyType:String = null;
		
		private function handleQKeyManagerChange():void
		{
			var keytypes:Array = WeaveAPI.QKeyManager.getAllKeyTypes();
			for each(var keytype:String in keytypes)
			{
				_addKeyTypeToMenu(keytype,false);
			}
			
			invalidateDisplayList();
			validateNow();
		}
	}
}