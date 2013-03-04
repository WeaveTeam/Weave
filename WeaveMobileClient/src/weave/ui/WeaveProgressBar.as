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
	
	import mx.core.IVisualElementContainer;
	
	import spark.components.Label;
	
	import weave.api.WeaveAPI;
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
				var index:int;
				if(parent is IVisualElementContainer){
					index = (parent as IVisualElementContainer).numElements - 1;
				}
				else{
					index = parent.numChildren-1;
				}
				UIUtils.spark_setChildIndex(parent, this,index );
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
