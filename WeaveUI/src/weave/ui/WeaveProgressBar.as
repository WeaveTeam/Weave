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
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	
	import weave.api.getCallbackCollection;

	/**
	 * This is a progress bar for Weave which updates on tasks added to the ProgressIndicator
	 * @author kmonico
	 * @author adufilie
	 * @author skolman
	 */
	public class WeaveProgressBar extends ProgressBar
	{
		public static var debug:Boolean = false;
		
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
		
		private const _stayBehind:Dictionary = new Dictionary(true);
		
		/**
		 * Call this function to prevent the progress bar from obscuring a specific DisplayObject.
		 */
		public function stayBehind(object:DisplayObject):void
		{
			_stayBehind[object] = true;
		}
		
		private function handleEnterFrame(event:Event = null):void
		{
			if (parent && visible)
			{
				y = parent.height - height;
				var myIndex:int = parent.getChildIndex(this);
				while (myIndex > 0 && _stayBehind[parent.getChildAt(myIndex - 1)])
					myIndex--;
				var desiredIndex:int = parent.numChildren - 1;
				while (myIndex < desiredIndex && !_stayBehind[parent.getChildAt(myIndex + 1)])
					myIndex++;
				parent.setChildIndex(this, myIndex);
			}
		}
		
		private var _maxProgressBarValue:int = 0;
		
		private function handleProgressIndicatorCounterChange():void
		{
			var pendingCount:int = WeaveAPI.ProgressIndicator.getTaskCount();
			var tempString:String = pendingCount + " Background Task" + (pendingCount == 1 ? '' : 's');
			//tempString += '\n' + (WeaveAPI.ProgressIndicator as ProgressIndicator).getDescriptions().join('\n');
			
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
			
			if (debug)
				trace('Progress:', WeaveAPI.ProgressIndicator.getNormalizedProgress());
		}
	}
}
