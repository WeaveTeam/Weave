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
	import flash.events.Event;
	
	import spark.components.Label;
	
	import weave.api.getCallbackCollection;
	import weave.core.UIUtils;

	/**
	 * This is a progress bar for Weave which updates on tasks added to the ProgressIndicator
	 * @author kmonico
	 * @author adufilie
	 * @author skolman
	 */
	public class WeaveProgressBar extends Label
	{
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			visible = false;
			mouseChildren = false;
			includeInLayout = false;
			setStyle("color", 0xFFFFFF); //color of text
			setStyle('textAlign','center');
			setStyle('verticalAlign','middle');
			setStyle('fontSize',14);
			text = '';
			minHeight = height = 20;
			minWidth = width = 250;
			x = 0;
			
			getCallbackCollection(WeaveAPI.ProgressIndicator).addGroupedCallback(this, handleProgressIndicatorCounterChange);
			
			addEventListener(Event.ENTER_FRAME, handleEnterFrame);
			
			handleProgressIndicatorCounterChange();
		}
		
		public var borderColor:int = 0x404040;
		public var barColor:int = 0x808080;
		public var backgroundColor:int = 0x000000;
		
		private function handleEnterFrame(event:Event = null):void
		{
			if (parent && visible)
			{
				y = parent.height - height;
				UIUtils.spark_setChildIndex(parent, this, parent.numChildren - 1);
			}
		}
		
		private var _maxProgressBarValue:int = 0;
		
		public function setProgress(norm:Number):void
		{
			validateSize();
			graphics.clear();
			
			graphics.lineStyle(1, borderColor, 1);
			graphics.beginFill(backgroundColor, 1.0);
			graphics.drawRect(0, 0, width - 1, height - 1);
			
			graphics.lineStyle(1, 0, 0);
			graphics.beginFill(barColor, 1.0);
			graphics.drawRect(0, 0, width * norm - 1, height - 1);
		}
		
		private function handleProgressIndicatorCounterChange():void
		{
			var pendingCount:int = WeaveAPI.ProgressIndicator.getTaskCount();
			var tempString:String = pendingCount + " Background Task" + (pendingCount == 1 ? '' : 's');
			
			text = tempString;
			
			if (pendingCount == 0) // hide progress bar and text area
			{
				visible = false;
				setProgress(0); // reset progress bar
				
				_maxProgressBarValue = 0;
			}
			else // display progress bar and text area
			{
				if (pendingCount > _maxProgressBarValue)
					_maxProgressBarValue = pendingCount;
				
				setProgress(WeaveAPI.ProgressIndicator.getNormalizedProgress());
				visible = true;
				handleEnterFrame();
			}
		}
	}
}
