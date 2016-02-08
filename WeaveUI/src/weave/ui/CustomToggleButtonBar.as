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
	import mx.controls.ToggleButtonBar;

	/**
	 * BUG FIX: hiliteSelectedNavItem crashes because it calls getChildAt() with a bad index.
	 * BUG FIX: selectedIndex is out of sync with _selectedIndex
	 * 
	 * @author adufilie
	 */
	public class CustomToggleButtonBar extends ToggleButtonBar
	{
		override protected function hiliteSelectedNavItem(index:int):void
		{
			if (index < numChildren)
				super.hiliteSelectedNavItem(index);
		}
		override public function set selectedIndex(value:int):void
		{
			if (value != selectedIndex)
			{
				super.selectedIndex = value;
				commitProperties();
				return;
			}
			
			super.selectedIndex = value;
		}
	}
}
