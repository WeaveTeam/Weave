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
	import flash.display.DisplayObject;
	
	import mx.containers.Canvas;
	
	import weave.core.LinkableHashMap;
	import weave.core.UIUtils;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;

	/**
	 * FOR TESTING PURPOSES ONLY
	 * 
	 * @author adufilie
	 */
	public class UITest extends DraggablePanel
	{
		public function UITest()
		{
			super();

			// this is where the magic happens
			UIUtils.linkDisplayObjects(visCanvas, children);

			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";

			this.autoLayout = true;
			
			addChild(visCanvas);
			
			visCanvas.percentHeight = 100;
			visCanvas.percentWidth = 100;
		}

		protected const visCanvas:Canvas = new Canvas();
		
		public const children:LinkableHashMap = newLinkableChild(this, LinkableHashMap);
	}
}
