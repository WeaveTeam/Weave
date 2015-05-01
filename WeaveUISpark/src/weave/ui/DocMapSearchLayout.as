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
	import flash.geom.Point;
	
	import mx.core.ILayoutElement;
	
	import spark.components.IItemRenderer;
	import spark.layouts.supportClasses.LayoutBase;
	
	import weave.api.reportError;
	import weave.primitives.ZoomBounds;
	import weave.visualization.layers.PlotManager;
	
	public class DocMapSearchLayout extends LayoutBase
	{
		public var zoomBounds:ZoomBounds;
		public const tempPoint:Point = new Point();
		
		override public function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			if (!zoomBounds)
			{
				reportError("zoomBounds is not set");
				return;
			}
			
			var layoutElement:ILayoutElement;
			var count:uint = target.numElements;
			for (var i:int = 0; i < count; i++)
			{
				if (useVirtualLayout)
					layoutElement = target.getVirtualElementAt(i);
				else
					layoutElement = target.getElementAt(i);
				
				var itemRenderer:IItemRenderer = layoutElement as IItemRenderer;
				var query:DocMapSearchQuery = itemRenderer.data as DocMapSearchQuery;
				if (!query)
				{
					reportError('item renderer data is not DocMapSearchQuery');
					continue;
				}
				
				tempPoint.x = query.x.value;
				tempPoint.y = query.y.value;
				zoomBounds.projectDataToScreen(tempPoint);
				
				layoutElement.setLayoutBoundsPosition(tempPoint.x, tempPoint.y);
			}
		}
	}
}
