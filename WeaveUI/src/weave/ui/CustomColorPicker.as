/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.ui
{
	import mx.controls.ColorPicker;
	import mx.core.mx_internal;
	import mx.events.DropdownEvent;
	
	import weave.core.UIUtils;
	
	use namespace mx_internal;

	/**
	 * Added functionality: The current selectedColor value can be selected again with the popup and still trigger a change event.
	 * 
	 * @author adufilie
	 */
	public class CustomColorPicker extends ColorPicker
	{
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			addEventListener(DropdownEvent.OPEN, handleOpen);
		}
		
		public function get hasFocus():Boolean
		{
			return UIUtils.hasFocus(this) || UIUtils.hasFocus(dropdown);
		}
		
		private function handleOpen(event:DropdownEvent):void
		{
			// This makes it so the same color can be selected again while still triggering a change event.
			super.selectedColor = selectedColor | 0xFF000000;
			dropdown.selectedColor = selectedColor;
		}
		
		[Bindable("change")]
		[Bindable("valueCommit")]
		[Inspectable(category="General", defaultValue="0", format="Color")]
		override public function get selectedColor():uint
		{
			return super.selectedColor & 0xFFFFFF;
		}
		
		override public function set selectedColor(value:uint):void
		{
			super.selectedColor = value;
		}
	}
}
