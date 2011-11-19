/*
	Weave (Web-based Analysis and Visualization Environment)
	Copyright (C) 2008-2011 University of Massachusetts Lowell
	
	This file is a part of Weave.
	
	Weave is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License, Version 3,
	as published by the Free Software Foundation.
	
	Weave is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.ui.settings
{
	import flash.text.Font;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.core.ClassFactory;
	import mx.events.FlexEvent;
	
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