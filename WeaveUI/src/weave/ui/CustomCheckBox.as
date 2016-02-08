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
	import mx.controls.CheckBox;
	
	import weave.core.UIUtils;
	
	/**
	 * Draws an invisible rectangle so it's easier to click.
	 */
	public class CustomCheckBox extends CheckBox
	{
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			graphics.clear();
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			UIUtils.drawInvisiblePolygon(this);
		}
	}
}
