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

package weave.ui
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	
	import mx.controls.DataGrid;
	import mx.controls.listClasses.ListRowInfo;
	import mx.core.mx_internal;

	use namespace mx_internal;	                          

	/**
	 * This is a wrapper around a DataGrid to fix a bug with the mx_internal addMask() function
	 * which was introduced in Flex 3.6 SDK. The issue is the lockedColumnContent is instantiated
	 * and contains invalid data when the lockedColumnCount is 0. 
	 * 
	 * @author kmonico
	 */	
	public class CustomDataGrid extends DataGrid
	{
		/**
		 * There's a bug in Flex 3.6 SDK where the locked column content may not be updated
		 * at the same time as the listItems for the DataGrid. This is an issue because they
		 * could have different lengths, and thus cause a null reference error.
		 * 
		 * @param layoutChanged If the layout changed.
		 */		
		override mx_internal function addClipMask(layoutChanged:Boolean):void
		{
			if (lockedColumnCount == 0)
				lockedColumnContent = null; // this should be null if there are no locked columns
			
			super.addClipMask(layoutChanged);
		}
		
		public static const VERTICAL_SCROLL:String = "Vertical";
		public static const HORIZONTAL_SCROLL:String = "Horizontal";
		public function getScrollWidth(scrollBar:String):int
		{
			if (scrollBar == VERTICAL_SCROLL && verticalScrollBar)
			{
				return verticalScrollBar.getExplicitOrMeasuredWidth();
			}
			else if (scrollBar == HORIZONTAL_SCROLL && horizontalScrollBar)
			{
				return horizontalScrollBar.getExplicitOrMeasuredWidth();
			}
			
			return 0;
		}
	}
}