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
	import flash.events.Event;
	
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	import mx.core.IVisualElementContainer;
	import mx.managers.PopUpManager;
	
	import weave.api.WeaveAPI;
	import weave.api.getCallbackCollection;
	import weave.api.reportError;

	/**
	 * This is a progress bar for Weave which updates on tasks added to the ProgressIndicator
	 * @author kmonico
	 * @author adufilie
	 * @author skolman
	 */
	public class WeaveProgressBar extends ProgressBar
	{
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			visible = false;
			mouseChildren = false;
			includeInLayout = false;
			setStyle("trackHeight", 16);
			setStyle("borderColor", 0x000000);
			setStyle("color", 0xFFFFFF); //color of text
			setStyle("barColor", "haloBlue");
			setStyle("trackColors", [0x000000, 0x000000]);
			labelPlacement = ProgressBarLabelPlacement.CENTER;
			label = '';
			mode = "manual";
			minHeight = 16;
			minWidth = 135;
			x = 0;
			
			getCallbackCollection(WeaveAPI.ProgressIndicator).addGroupedCallback(this, handleProgressIndicatorCounterChange);
			
			addEventListener(Event.ENTER_FRAME, handleEnterFrame);
			
			handleProgressIndicatorCounterChange();
		}
		
		private function handleEnterFrame(event:Event = null):void
		{
			if (parent && visible)
			{
				y = parent.height - height;
				if(parent is IVisualElementContainer){
					(parent as IVisualElementContainer).setElementIndex(this, (parent as IVisualElementContainer).numElements - 1);
				}
				else{
					parent.setChildIndex(this, parent.numChildren  - 1);
				}
				
			}
		}
		
		private var _maxProgressBarValue:int = 0;
		
		private function handleProgressIndicatorCounterChange():void
		{
			var pendingCount:int = WeaveAPI.ProgressIndicator.getTaskCount();
			var tempString:String = pendingCount + " Background Task" + (pendingCount == 1 ? '' : 's');
			
			label = tempString;
			
			if (pendingCount == 0) // hide progress bar and text area
			{
				visible = false;
				setProgress(0, 1); // reset progress bar
				
				_maxProgressBarValue = 0;
			}
			else // display progress bar and text area
			{
				if (pendingCount > _maxProgressBarValue)
					_maxProgressBarValue = pendingCount;
				
				setProgress(WeaveAPI.ProgressIndicator.getNormalizedProgress(), 1); // progress between 0 and 1
				visible = true;
				handleEnterFrame();
			}
		}
	}
}
