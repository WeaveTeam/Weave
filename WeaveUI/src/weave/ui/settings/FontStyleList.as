// ActionScript file

package weave.ui.settings
{
	import flash.text.Font;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.core.ClassFactory;
	import mx.events.DropdownEvent;
	import mx.events.FlexEvent;
	
	import weave.Weave;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.ui.CustomComboBox;

	public class FontStyleList extends CustomComboBox
	{
		private var fontList:ArrayCollection;
		
		public function FontStyleList()
		{
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, listCreated);
		}

		private function listCreated(e:FlexEvent):void
		{
			fontList = new ArrayCollection(Font.enumerateFonts(true));
			labelField = "fontName";
			setStyle("fontSize",10);
			setStyle('textDecoration','none');
			setStyle('fontStyle','normal');
			setStyle('fontWeight','normal');
			var fontSort:Sort = new Sort();
			fontSort.fields = [new SortField("fontName")];
			fontList.sort = fontSort;
			dataProvider = fontList;
			itemRenderer = new ClassFactory(FontStyleRenderer);
			dropdown.variableRowHeight = true;
		}
	}
}